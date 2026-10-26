import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../data/music_onboarding_data.dart';
import '../data/mock_data.dart';
import '../config/api_config.dart';
import 'lyrics_service.dart';
import 'audio_stream_resolver.dart';

class YTMusicService {
  static String get baseUrl => ApiConfig.baseUrl;

  static String _cleanText(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  static String _upgradeSaavnImage(String? raw) {
    if (raw == null || raw.isEmpty || raw.contains('default-film.png')) return '';
    return raw.replaceAll('50x50', '500x500').replaceAll('150x150', '500x500');
  }

  static const String _ytmSearchUrl = 'https://music.youtube.com/youtubei/v1/search?prettyPrint=false';
  static const Map<String, String> _ytmHeaders = {
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Origin': 'https://music.youtube.com',
    'Referer': 'https://music.youtube.com/'
  };
  static const Map<String, dynamic> _ytmContext = {
    'client': {
      'clientName': 'WEB_REMIX',
      'clientVersion': '1.20240101.01.00',
      'hl': 'en',
      'gl': 'IN'
    }
  };

  /// 1. SEARCH SONGS (Direct JioSaavn 320kbps + MP3Paw/dlsrv Global Engine + YouTube Music)
  static Future<List<Song>> search(String query) async {
    final cleanQuery = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    // Query JioSaavn 320kbps streams, dlsrv worldwide catalog, and YouTube Music concurrently
    final futures = await Future.wait([
      _searchBackendOrSaavn(cleanQuery),
      _searchDlsrv(cleanQuery),
      _searchYtmDirect(cleanQuery),
    ]);

    final saavnSongs = futures[0];
    final dlsrvSongs = futures[1];
    final ytmSongs = futures[2];

    final combined = <Song>[];
    final seen = <String>{};

    String cleanKey(String t, String a) =>
        '${t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}::${a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

    // 1. High-fidelity JioSaavn 320kbps tracks prioritized for instant 0.1s playback
    for (final s in saavnSongs) {
      final k = cleanKey(s.title, s.artist);
      if (seen.add(k) && seen.add(s.id)) {
        combined.add(s);
      }
    }

    // 2. High-speed MP3Paw/dlsrv worldwide tracks (AUR, Encore band, Tanveer Evan, indies, live)
    for (final s in dlsrvSongs) {
      final k = cleanKey(s.title, s.artist);
      if (seen.add(k) && seen.add(s.id)) {
        combined.add(s);
      }
    }

    // 3. Supplemental YouTube Music tracks
    for (final s in ytmSongs) {
      final k = cleanKey(s.title, s.artist);
      if (seen.add(k) && seen.add(s.id)) {
        combined.add(s);
      }
    }

    if (combined.isNotEmpty) return combined;

    // Step 4: Graceful local search fallback
    final qLower = cleanQuery.toLowerCase();
    return MockData.allSongs.where((s) {
      return s.title.toLowerCase().contains(qLower) || s.artist.toLowerCase().contains(qLower);
    }).toList();
  }

  /// Search worldwide tracks via dlsrv engine (used by MP3Paw for 100% videoId accuracy)
  static Future<List<Song>> _searchDlsrv(String query) async {
    try {
      final uri = Uri.parse('https://media.dlsrv.online/search/data');
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Origin': 'https://v5.mp3paw.link',
          'Referer': 'https://v5.mp3paw.link/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        },
        body: jsonEncode({'query': query}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = data['data'] as List? ?? [];
        final songs = <Song>[];
        for (final item in list) {
          if (item is! Map) continue;
          final videoId = item['videoId']?.toString() ?? '';
          if (videoId.isEmpty || !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(videoId)) continue;

          final rawTitle = item['title']?.toString() ?? 'Unknown Track';
          final title = _cleanText(rawTitle);
          final durationStr = item['duration']?.toString() ?? '3:30';
          final parts = durationStr.split(':').map((s) => int.tryParse(s) ?? 0).toList();
          final durSec = parts.length == 2
              ? parts[0] * 60 + parts[1]
              : (parts.length == 3 ? parts[0] * 3600 + parts[1] * 60 + parts[2] : 210);

          String artist = 'Soundifly Artist';
          if (rawTitle.contains(' - ')) {
            artist = rawTitle.split(' - ').first.trim();
          } else if (rawTitle.contains(' by ')) {
            artist = rawTitle.split(' by ').last.split('|').first.trim();
          } else if (rawTitle.contains('|')) {
            artist = rawTitle.split('|').last.trim();
          }

          final thumb = item['imgSrc']?.toString() ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

          songs.add(Song(
            id: videoId,
            title: title,
            artist: artist.isNotEmpty ? artist : 'Soundifly Artist',
            album: 'Single',
            coverUrl: thumb,
            audioUrl: '$baseUrl/stream/$videoId',
            duration: Duration(seconds: durSec),
            genre: 'YouTube Music',
            releaseYear: '2026',
          ));
        }
        return songs;
      }
    } catch (e) {
      debugPrint('[YTMusicService] dlsrv search note: $e');
    }
    return [];
  }

  static Future<List<Song>> _searchYtmDirect(String query) async {
    final songs = <Song>[];
    final seenIds = <String>{};

    Future<void> fetchWithParams(String? params) async {
      try {
        final bodyMap = <String, dynamic>{
          'context': _ytmContext,
          'query': query,
        };
        if (params != null) {
          bodyMap['params'] = params;
        }
        final res = await http.post(
          Uri.parse(_ytmSearchUrl),
          headers: _ytmHeaders,
          body: jsonEncode(bodyMap),
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data is Map<String, dynamic>) {
            final parsed = _parseYtmJson(data);
            for (final s in parsed) {
              if (seenIds.add(s.id)) {
                songs.add(s);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[YTMusicService] Direct YTM search note: $e');
      }
    }

    // 1. First fetch with 'songs' filter (official studio tracks via sigma67/ytmusicapi)
    await fetchWithParams('EgWKAQIIAWoKEAoQCRADEAQQBQ%3D%3D');

    // 2. If fewer than 5 songs returned, also fetch unfiltered (catches Top Result card, live versions, indie bands)
    if (songs.length < 5) {
      await fetchWithParams(null);
    }

    return songs;
  }

  static List<Song> _parseYtmJson(Map<String, dynamic> data) {
    final songs = <Song>[];
    final seen = <String>{};

    final tabs = data['contents']?['tabbedSearchResultsRenderer']?['tabs'] as List? ?? [];
    if (tabs.isEmpty || tabs[0] is! Map) return songs;

    final contents = tabs[0]['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List? ?? [];

    for (final sec in contents) {
      if (sec is! Map) continue;

      // 1. Top Result Card (musicCardShelfRenderer)
      final card = sec['musicCardShelfRenderer'];
      if (card is Map) {
        final titleRuns = card['title']?['runs'] as List?;
        final title = _cleanText(titleRuns != null && titleRuns.isNotEmpty && titleRuns[0] is Map ? titleRuns[0]['text']?.toString() : '');
        final subRuns = card['subtitle']?['runs'] as List? ?? [];
        String artist = 'Artist';
        if (subRuns.length > 2 && subRuns[2] is Map) {
          artist = _cleanText(subRuns[2]['text']?.toString());
        } else if (subRuns.isNotEmpty && subRuns[0] is Map) {
          artist = _cleanText(subRuns[0]['text']?.toString());
        }
        final videoId = card['onTap']?['watchEndpoint']?['videoId']?.toString() ??
            card['buttons']?[0]?['buttonRenderer']?['command']?['watchEndpoint']?['videoId']?.toString();
        final thumbs = card['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List? ?? [];
        final thumb = thumbs.isNotEmpty && thumbs.last is Map ? thumbs.last['url']?.toString() ?? '' : '';

        if (title.isNotEmpty && videoId != null && videoId.isNotEmpty && seen.add(videoId)) {
          songs.add(Song(
            id: videoId,
            title: title,
            artist: artist,
            album: 'Top Result',
            coverUrl: thumb.isNotEmpty ? thumb : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
            audioUrl: '$baseUrl/stream/$videoId',
            duration: const Duration(seconds: 210),
            genre: 'YouTube Music',
            releaseYear: '2026',
          ));
        }
      }

      // 2. Music Shelf or Item Section
      final items = (sec['musicShelfRenderer']?['contents'] ?? sec['itemSectionRenderer']?['contents']) as List? ?? [];
      for (final item in items) {
        if (item is! Map) continue;
        final r = item['musicResponsiveListItemRenderer'];
        if (r == null || r is! Map) continue;

        final flex0 = r['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
        final title = _cleanText(flex0 != null && flex0.isNotEmpty && flex0[0] is Map ? flex0[0]['text']?.toString() : 'Unknown Title');

        final flex1 = r['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List? ?? [];
        String artist = 'Various Artists';
        if (flex1.isNotEmpty && flex1[0] is Map) {
          artist = _cleanText(flex1[0]['text']?.toString() ?? 'Various Artists');
        }

        String album = 'Single';
        String durationStr = '3:30';

        for (int i = 1; i < flex1.length; i++) {
          if (flex1[i] is! Map) continue;
          final text = flex1[i]['text']?.toString().trim() ?? '';
          if (text == '•' || text.isEmpty) continue;
          if (RegExp(r'^\d+:\d+$').hasMatch(text)) {
            durationStr = text;
          } else if (text.length > 1) {
            album = _cleanText(text);
          }
        }

        final videoId = r['playlistItemData']?['videoId']?.toString() ??
            r['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId']?.toString();
        if (videoId == null || videoId.isEmpty || !seen.add(videoId)) continue;

        final thumbs = r['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List? ?? [];
        String thumb = '';
        if (thumbs.isNotEmpty && thumbs.last is Map) {
          thumb = thumbs.last['url']?.toString() ?? '';
        }

        final durParts = durationStr.split(':').map((s) => int.tryParse(s) ?? 0).toList();
        final durationSeconds = durParts.length == 2 ? durParts[0] * 60 + durParts[1] : 210;

        songs.add(Song(
          id: videoId,
          title: title,
          artist: artist,
          album: album,
          coverUrl: thumb.isNotEmpty ? thumb : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
          audioUrl: '$baseUrl/stream/$videoId',
          duration: Duration(seconds: durationSeconds),
          genre: 'YouTube Music',
          releaseYear: '2026',
        ));
      }
    }
    return songs;
  }

  static Future<List<Song>> _searchBackendOrSaavn(String query) async {
    // 1. Try Backend
    try {
      final uri = Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        final songs = data.map((item) => _parseSong(item as Map<String, dynamic>)).toList();
        if (songs.isNotEmpty) return songs;
      }
    } catch (_) {}

    // 2. Direct JioSaavn 320kbps fallback
    try {
      final saavnUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getResults&_format=json&n=25&p=1&q=${Uri.encodeComponent(query)}',
      );
      final saavnRes = await http.get(saavnUri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
      if (saavnRes.statusCode == 200) {
        final sData = jsonDecode(utf8.decode(saavnRes.bodyBytes));
        final list = sData['results'] as List? ?? [];
        final songs = <Song>[];

        for (final item in list) {
          if (item is Map) {
            final songId = 'saavn_${item['id']}';
            final title = _cleanText(item['song']?.toString());
            final artist = _cleanText(item['primary_artists']?.toString() ?? item['singers']?.toString());
            final album = _cleanText(item['album']?.toString());
            final img = _upgradeSaavnImage(item['image']?.toString());
            final durSec = int.tryParse(item['duration']?.toString() ?? '210') ?? 210;
            final directSaavnUrl = AudioStreamResolver.decryptSaavnUrl(item['encrypted_media_url']?.toString());
            final audioUrl = directSaavnUrl ?? '$baseUrl/stream/$songId';

            if (title.isNotEmpty) {
              songs.add(Song(
                id: songId,
                title: title,
                artist: artist.isNotEmpty ? artist : 'Soundifly Artist',
                album: album.isNotEmpty ? album : 'Single',
                coverUrl: img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
                audioUrl: audioUrl,
                duration: Duration(seconds: durSec),
                genre: item['language']?.toString() ?? 'Music',
                releaseYear: item['year']?.toString() ?? '2025',
              ));
            }
          }
        }
        return songs;
      }
    } catch (_) {}

    return [];
  }

  /// 1b. GET ARTIST TOP SONGS (JioSaavn 320kbps + YouTube Music with strict artist fidelity)
  static Future<List<Song>> getArtistSongs(String artistName) async {
    final cleanName = artistName.trim();
    if (cleanName.isEmpty) return [];

    final targetLower = cleanName.toLowerCase();
    final combined = <Song>[];
    final seen = <String>{};

    String cleanKey(String t, String a) =>
        '${t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}::${a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

    bool isArtistMatch(Song s) {
      final a = s.artist.toLowerCase();
      // Strict match: avoid other artists bleeding into profile
      return a.contains(targetLower) || targetLower.contains(a);
    }

    // 1. Fetch from JioSaavn for guaranteed 320kbps authentic artist tracks
    try {
      final saavnTracks = await _searchBackendOrSaavn(cleanName);
      for (final s in saavnTracks) {
        if (isArtistMatch(s)) {
          final k = cleanKey(s.title, s.artist);
          if (seen.add(k) && seen.add(s.id)) {
            combined.add(s);
          }
        }
      }
    } catch (e) {
      debugPrint('[YTMusicService] Saavn artist songs note: $e');
    }

    // 2. Fetch from dlsrv global engine (AUR, Encore band, Tanveer Evan, indies)
    try {
      final dlsrvTracks = await _searchDlsrv(cleanName);
      for (final s in dlsrvTracks) {
        if (isArtistMatch(s)) {
          final k = cleanKey(s.title, s.artist);
          if (seen.add(k) && seen.add(s.id)) {
            combined.add(s);
          }
        }
      }
    } catch (_) {}

    // 3. Fetch from YouTube Music and strictly filter
    try {
      final rawYtm = await _searchYtmDirect(cleanName);
      for (final s in rawYtm) {
        if (isArtistMatch(s)) {
          final k = cleanKey(s.title, s.artist);
          if (seen.add(k) && seen.add(s.id)) {
            combined.add(s);
          }
        }
      }
    } catch (e) {
      debugPrint('[YTMusicService] YTM artist songs note: $e');
    }

    if (combined.isNotEmpty) return combined;

    // 3. Fallback to backend endpoint if available
    try {
      final uri = Uri.parse('$baseUrl/artists/${Uri.encodeComponent(cleanName)}/songs');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(res.bodyBytes));
        final songs = list.map((item) => _parseSong(item as Map<String, dynamic>)).where(isArtistMatch).toList();
        if (songs.isNotEmpty) return songs;
      }
    } catch (_) {}

    return combined;
  }

  /// 2. SEARCH ARTISTS (Curated + Backend + JioSaavn + Deezer Unified Engine)
  static Future<List<Artist>> searchArtists(String query) async {
    final cleanQuery = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    final qLower = cleanQuery.toLowerCase();
    final List<Artist> results = [];
    final Set<String> seenNames = {};

    // 1. Curated Catalogue matches
    for (final ca in MusicOnboardingData.curatedArtists) {
      if (ca.matchesQuery(cleanQuery)) {
        seenNames.add(ca.name.toLowerCase());
        results.add(Artist(
          id: ca.id,
          name: ca.name,
          imageUrl: ca.imageUrl,
          bio: '${ca.artistTypeDisplay} • ${ca.languages.join(", ")}',
          monthlyListeners: ca.popularityScore,
          genres: [ca.genre, ...ca.languages],
        ));
      }
    }

    // 2. Try Backend Engine
    try {
      final backendUri = Uri.parse('$baseUrl/artists/search?q=${Uri.encodeComponent(cleanQuery)}');
      final res = await http.get(backendUri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        for (final item in data) {
          if (item is Map) {
            final name = _cleanText(item['name']?.toString());
            final lower = name.toLowerCase();
            if (name.isEmpty || seenNames.contains(lower)) continue;
            seenNames.add(lower);

            final img = item['imageUrl']?.toString() ?? '';
            final pop = (item['popularity'] as num?)?.toInt() ?? 1000;
            final typeStr = item['artistType']?.toString() ?? 'Singer';

            results.add(Artist(
              id: item['id']?.toString() ?? 'live_${name.hashCode}',
              name: name,
              imageUrl: img,
              monthlyListeners: pop,
              genres: [typeStr],
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[YTMusicService] Backend artist search note: $e');
    }

    // 3. Direct Resilient Fallback to JioSaavn & Deezer
    try {
      final saavnUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getArtistResults&_format=json&n=15&p=1&q=${Uri.encodeComponent(cleanQuery)}',
      );
      final saavnRes = await http.get(saavnUri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
      if (saavnRes.statusCode == 200) {
        final sData = jsonDecode(utf8.decode(saavnRes.bodyBytes));
        final list = sData['results'] as List? ?? [];
        for (final item in list) {
          if (item is Map) {
            final name = _cleanText(item['name']?.toString());
            final lower = name.toLowerCase();
            if (name.isEmpty || seenNames.contains(lower)) continue;
            if (!cleanQuery.contains(',') && (name.contains(',') || name.contains(';'))) continue;

            seenNames.add(lower);
            final rawImg = item['image']?.toString() ?? '';
            final img = _upgradeSaavnImage(rawImg);
            final ctr = int.tryParse(item['ctr']?.toString() ?? '0') ?? 1000;

            results.add(Artist(
              id: 'saavn_${item['id']}',
              name: name,
              imageUrl: img,
              monthlyListeners: ctr * 10,
              genres: [item['role']?.toString() ?? 'Artist'],
            ));
          }
        }
      }
    } catch (err) {
      debugPrint('[YTMusicService] JioSaavn artist fallback note: $err');
    }

    try {
      final dzUri = Uri.parse('https://api.deezer.com/search/artist?q=${Uri.encodeComponent(cleanQuery)}&limit=15');
      final dzRes = await http.get(dzUri).timeout(const Duration(seconds: 4));
      if (dzRes.statusCode == 200) {
        final dData = jsonDecode(utf8.decode(dzRes.bodyBytes));
        final list = dData['data'] as List? ?? [];
        for (final item in list) {
          if (item is Map) {
            final name = _cleanText(item['name']?.toString());
            final lower = name.toLowerCase();
            if (name.isEmpty || seenNames.contains(lower)) continue;
            seenNames.add(lower);

            final img = item['picture_big']?.toString() ?? item['picture_medium']?.toString() ?? '';
            final fans = (item['nb_fan'] as num?)?.toInt() ?? 500;

            results.add(Artist(
              id: 'dz_${item['id']}',
              name: name,
              imageUrl: img,
              monthlyListeners: fans,
              genres: ['Singer'],
            ));
          }
        }
      }
    } catch (err) {
      debugPrint('[YTMusicService] Deezer artist fallback note: $err');
    }

    results.sort((a, b) {
      final aLower = a.name.toLowerCase();
      final bLower = b.name.toLowerCase();
      final aExact = aLower == qLower;
      final bExact = bLower == qLower;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aPrefix = aLower.startsWith(qLower);
      final bPrefix = bLower.startsWith(qLower);
      if (aPrefix && !bPrefix) return -1;
      if (!aPrefix && bPrefix) return 1;

      return b.monthlyListeners.compareTo(a.monthlyListeners);
    });

    return results;
  }

  /// 3. SEARCH ALBUMS (Backend + JioSaavn + Deezer Unified Engine)
  static Future<List<Album>> searchAlbums(String query) async {
    final cleanQuery = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    final qLower = cleanQuery.toLowerCase();
    final List<Album> results = [];
    final Set<String> seenKeys = {};

    // 1. Try Backend Engine
    try {
      final backendUri = Uri.parse('$baseUrl/albums/search?q=${Uri.encodeComponent(cleanQuery)}');
      final res = await http.get(backendUri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        for (final item in data) {
          if (item is Map) {
            final title = _cleanText(item['title']?.toString());
            final artist = _cleanText(item['artist']?.toString());
            if (title.isEmpty) continue;

            final key = '${title.toLowerCase()}::${artist.toLowerCase()}';
            if (seenKeys.contains(key)) continue;
            seenKeys.add(key);

            results.add(Album(
              id: item['id']?.toString() ?? 'live_alb_${title.hashCode}',
              title: title,
              artist: artist.isNotEmpty ? artist : 'Soundifly Artist',
              coverUrl: item['coverUrl']?.toString() ?? '',
              releaseYear: item['releaseYear']?.toString() ?? '2025',
              genre: item['genre']?.toString() ?? 'Music',
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[YTMusicService] Backend album search note: $e');
    }

    // 2. Direct Resilient Fallback to JioSaavn Album Search
    try {
      final saavnUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getAlbumResults&_format=json&n=15&p=1&q=${Uri.encodeComponent(cleanQuery)}',
      );
      final saavnRes = await http.get(saavnUri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
      if (saavnRes.statusCode == 200) {
        final sData = jsonDecode(utf8.decode(saavnRes.bodyBytes));
        final list = sData['results'] as List? ?? [];
        for (final item in list) {
          if (item is Map) {
            final title = _cleanText(item['title']?.toString() ?? item['name']?.toString());
            if (title.isEmpty) continue;

            String artist = '';
            if (item['primary_artists'] is String && (item['primary_artists'] as String).trim().isNotEmpty) {
              artist = item['primary_artists'];
            } else if (item['music'] is String && (item['music'] as String).trim().isNotEmpty) {
              artist = item['music'];
            } else if (item['artist'] is Map && item['artist']['singers'] is List) {
              final singers = item['artist']['singers'] as List;
              artist = singers.map((s) => s is Map ? s['name'] : s.toString()).join(', ');
            } else {
              artist = 'Various Artists';
            }
            artist = _cleanText(artist);

            final key = '${title.toLowerCase()}::${artist.toLowerCase()}';
            if (seenKeys.contains(key)) continue;
            seenKeys.add(key);

            final rawImg = item['image']?.toString() ?? '';
            final img = _upgradeSaavnImage(rawImg);

            results.add(Album(
              id: 'saavn_${item['albumid'] ?? item['id']}',
              title: title,
              artist: artist,
              coverUrl: img,
              releaseYear: item['year']?.toString() ?? '2025',
              genre: item['language']?.toString() ?? 'Music',
            ));
          }
        }
      }
    } catch (err) {
      debugPrint('[YTMusicService] JioSaavn album fallback note: $err');
    }

    // 3. Fallback to Deezer Album Search
    try {
      final dzUri = Uri.parse('https://api.deezer.com/search/album?q=${Uri.encodeComponent(cleanQuery)}&limit=15');
      final dzRes = await http.get(dzUri).timeout(const Duration(seconds: 4));
      if (dzRes.statusCode == 200) {
        final dData = jsonDecode(utf8.decode(dzRes.bodyBytes));
        final list = dData['data'] as List? ?? [];
        for (final item in list) {
          if (item is Map) {
            final title = _cleanText(item['title']?.toString());
            if (title.isEmpty) continue;

            final artist = _cleanText(item['artist'] is Map ? item['artist']['name']?.toString() : 'Various Artists');
            final key = '${title.toLowerCase()}::${artist.toLowerCase()}';
            if (seenKeys.contains(key)) continue;
            seenKeys.add(key);

            final img = item['cover_big']?.toString() ?? item['cover_medium']?.toString() ?? '';

            results.add(Album(
              id: 'dz_${item['id']}',
              title: title,
              artist: artist,
              coverUrl: img,
              releaseYear: '2025',
              genre: 'Music',
            ));
          }
        }
      }
    } catch (err) {
      debugPrint('[YTMusicService] Deezer album fallback note: $err');
    }

    results.sort((a, b) {
      final aLower = a.title.toLowerCase();
      final bLower = b.title.toLowerCase();
      final aExact = aLower == qLower;
      final bExact = bLower == qLower;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aPrefix = aLower.startsWith(qLower);
      final bPrefix = bLower.startsWith(qLower);
      if (aPrefix && !bPrefix) return -1;
      if (!aPrefix && bPrefix) return 1;

      return 0;
    });

    return results;
  }

  /// 4. GET ALBUM DETAILS (With full tracks)
  static Future<Album?> getAlbumDetails(String albumId) async {
    final cleanId = albumId.replaceAll('saavn_', '').replaceAll('dz_', '');

    // Step 1: Try backend
    try {
      final uri = Uri.parse('$baseUrl/albums/$albumId');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        final tracksList = (data['tracks'] as List? ?? []).map((t) => _parseSong(t as Map<String, dynamic>)).toList();
        return Album(
          id: data['id'] ?? albumId,
          title: data['title'] ?? 'Album',
          artist: data['artist'] ?? 'Various Artists',
          coverUrl: data['coverUrl'] ?? '',
          releaseYear: data['releaseYear'] ?? '2025',
          genre: data['genre'] ?? 'Music',
          tracks: tracksList,
        );
      }
    } catch (e) {
      debugPrint('[YTMusicService] Backend album details note: $e');
    }

    // Step 2: Direct JioSaavn album details fallback
    try {
      final url = 'https://www.jiosaavn.com/api.php?__call=content.getAlbumDetails&albumid=$cleanId&_format=json';
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final sData = jsonDecode(utf8.decode(res.bodyBytes));
        if (sData is Map && sData['title'] != null) {
          final title = _cleanText(sData['title']?.toString());
          final artist = _cleanText(sData['primary_artists']?.toString() ?? 'Various Artists');
          final coverUrl = _upgradeSaavnImage(sData['image']?.toString());
          final songs = sData['songs'] as List? ?? [];

          final tracks = <Song>[];
          for (final s in songs) {
            if (s is Map) {
              final songId = 'saavn_${s['id']}';
              final sTitle = _cleanText(s['song']?.toString());
              final sArtist = _cleanText(s['primary_artists']?.toString() ?? s['singers']?.toString() ?? artist);
              final durSec = int.tryParse(s['duration']?.toString() ?? '210') ?? 210;

              final directSaavnUrl = AudioStreamResolver.decryptSaavnUrl(s['encrypted_media_url']?.toString());
              final audioUrl = directSaavnUrl ?? '$baseUrl/stream/$songId';

              tracks.add(Song(
                id: songId,
                title: sTitle.isNotEmpty ? sTitle : 'Track',
                artist: sArtist.isNotEmpty ? sArtist : artist,
                album: title,
                coverUrl: _upgradeSaavnImage(s['image']?.toString()).isNotEmpty ? _upgradeSaavnImage(s['image']?.toString()) : coverUrl,
                audioUrl: audioUrl,
                duration: Duration(seconds: durSec),
                genre: s['language']?.toString() ?? 'Music',
                releaseYear: sData['year']?.toString() ?? '2025',
              ));
            }
          }

          return Album(
            id: 'saavn_$cleanId',
            title: title,
            artist: artist,
            coverUrl: coverUrl,
            releaseYear: sData['year']?.toString() ?? '2025',
            genre: sData['language']?.toString() ?? 'Music',
            tracks: tracks,
          );
        }
      }
    } catch (err) {
      debugPrint('[YTMusicService] JioSaavn album details fallback note: $err');
    }

    return null;
  }

  static Future<List<String>> getSuggestions(String query) async {
    final cleanQuery = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/suggestions?q=${Uri.encodeComponent(cleanQuery)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((s) => s.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Song>> getTrending() async {
    try {
      final uri = Uri.parse('$baseUrl/trending');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        final songs = data.map((item) => _parseSong(item as Map<String, dynamic>)).toList();
        if (songs.isNotEmpty) return songs;
      }
    } catch (_) {}

    // Direct client fallback to JioSaavn Top Trending Hits with direct 320kbps URLs
    try {
      final saavnUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getResults&_format=json&n=25&p=1&q=Top+Trending+Hits+2026',
      );
      final saavnRes = await http.get(saavnUri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
      if (saavnRes.statusCode == 200) {
        final sData = jsonDecode(utf8.decode(saavnRes.bodyBytes));
        final list = sData['results'] as List? ?? [];
        final songs = <Song>[];
        for (final item in list) {
          if (item is Map) {
            final songId = 'saavn_${item['id']}';
            final title = _cleanText(item['song']?.toString());
            final artist = _cleanText(item['primary_artists']?.toString() ?? item['singers']?.toString());
            final album = _cleanText(item['album']?.toString());
            final img = _upgradeSaavnImage(item['image']?.toString());
            final durSec = int.tryParse(item['duration']?.toString() ?? '210') ?? 210;
            final directUrl = AudioStreamResolver.decryptSaavnUrl(item['encrypted_media_url']?.toString());

            if (title.isNotEmpty) {
              songs.add(Song(
                id: songId,
                title: title,
                artist: artist.isNotEmpty ? artist : 'Top Artist',
                album: album.isNotEmpty ? album : 'Trending Hits',
                coverUrl: img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
                audioUrl: directUrl ?? '$baseUrl/stream/$songId',
                duration: Duration(seconds: durSec),
                genre: item['language']?.toString() ?? 'Trending',
                releaseYear: item['year']?.toString() ?? '2026',
              ));
            }
          }
        }
        if (songs.isNotEmpty) return songs;
      }
    } catch (_) {}

    return MockData.allSongs;
  }

  static Future<List<LyricLine>> getLyrics(String title, String artist, {int? durationSeconds}) async {
    try {
      final tempSong = Song(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        artist: artist,
        album: '',
        coverUrl: '',
        audioUrl: '',
        duration: Duration(seconds: durationSeconds ?? 210),
      );
      final parsed = await LyricsService.getLyrics(tempSong);
      return parsed.lines;
    } catch (e) {
      return [];
    }
  }

  static Song _parseSong(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? 'yt_${DateTime.now().millisecondsSinceEpoch}',
      title: _cleanText(json['title']?.toString() ?? 'Unknown Track'),
      artist: _cleanText(json['artist']?.toString() ?? 'Unknown Artist'),
      album: _cleanText(json['album']?.toString() ?? 'Single'),
      coverUrl: json['coverUrl'] ?? 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      audioUrl: json['audioUrl'] ?? '$baseUrl/stream/${json['id']}',
      duration: Duration(seconds: json['durationSeconds'] ?? 210),
      genre: json['genre'] ?? 'Soundifly Stream',
      releaseYear: json['releaseYear'] ?? '2026',
      lyrics: const [],
    );
  }
}
