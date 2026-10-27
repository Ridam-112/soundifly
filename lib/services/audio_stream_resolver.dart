import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dart_des/dart_des.dart';
import '../models/song.dart';

class AudioStreamResolver {
  static final Map<String, _CachedUrl> _urlCache = {};
  static final List<int> _saavnDesKey = utf8.encode('38346591');

  // Cache entries expire after 3 hours
  static const Duration _cacheExpiry = Duration(hours: 3);

  static const Map<String, String> _saavnHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  /// Decrypts JioSaavn encrypted media url into direct MP4 CDN URL with selectable bitrate (320, 160, 96)
  static String? decryptSaavnUrl(String? encryptedMediaUrl, {String quality = '320'}) {
    if (encryptedMediaUrl == null || encryptedMediaUrl.trim().isEmpty) return null;
    try {
      final encryptedBytes = base64.decode(encryptedMediaUrl.trim());
      final des = DES(key: _saavnDesKey, mode: DESMode.ECB, paddingType: DESPaddingType.PKCS7);
      final decryptedBytes = des.decrypt(encryptedBytes);
      final rawUrl = utf8.decode(decryptedBytes);
      if (rawUrl.isEmpty) return null;

      if (quality == '320') {
        return rawUrl.replaceAll('_96.mp4', '_320.mp4').replaceAll('_160.mp4', '_320.mp4');
      } else if (quality == '160') {
        return rawUrl.replaceAll('_96.mp4', '_160.mp4').replaceAll('_320.mp4', '_160.mp4');
      } else {
        return rawUrl.replaceAll('_320.mp4', '_96.mp4').replaceAll('_160.mp4', '_96.mp4');
      }
    } catch (e) {
      debugPrint('[AudioStreamResolver] Saavn decrypt error: $e');
      return null;
    }
  }

  /// Resolves the fastest direct playable CDN audio URL for any song.
  /// Priority:
  /// 1. Direct CDN URLs (instant)
  /// 2. In-memory cache (instant)
  /// 3. JioSaavn DES decrypt for saavn_ IDs
  /// 4. Smart JioSaavn Matcher (authorized high-fidelity 320kbps/160kbps AAC stream)
  /// 5. Raw stream URL
  static Future<String?> resolveStreamUrl(Song song) async {
    final rawUrl = song.audioUrl.trim();

    // 1. Direct playable CDN audio URL
    if (_isDirectAudioUrl(rawUrl)) {
      return rawUrl;
    }

    // 2. In-memory cache
    final cached = _urlCache[song.id];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    // 3. JioSaavn song ID — instant DES decrypt
    if (song.id.startsWith('saavn_')) {
      final resolved = await _resolveSaavnById(song.id);
      if (resolved != null) {
        _urlCache[song.id] = _CachedUrl(resolved);
        return resolved;
      }
    }

    // 4. Smart JioSaavn match (authorized 320kbps MP4 CDN URL)
    final saavnMatched = await matchSaavnStream(song.title, song.artist);
    if (saavnMatched != null && saavnMatched.isNotEmpty) {
      _urlCache[song.id] = _CachedUrl(saavnMatched);
      return saavnMatched;
    }

    // 5. If raw URL is valid and non-empty (e.g. custom or backend stream URL)
    if (rawUrl.isNotEmpty && !rawUrl.contains('/stream/undefined')) {
      return rawUrl;
    }

    return null;
  }

  /// Resolve alternative fallback stream if primary playback stream fails in AudioPlayer
  static Future<String?> resolveFallbackStreamUrl(Song song) async {
    // Invalidate stale or blocked cached entry
    _urlCache.remove(song.id);

    // 1. If it's a JioSaavn song ID, attempt 160kbps bitrate (guaranteed on all Saavn tracks)
    if (song.id.startsWith('saavn_')) {
      final resolved = await _resolveSaavnById(song.id, quality: '160');
      if (resolved != null) {
        _urlCache[song.id] = _CachedUrl(resolved);
        return resolved;
      }
    }

    // 2. Attempt intelligent JioSaavn 160kbps MP4 match
    final saavnUrl = await matchSaavnStream(song.title, song.artist, quality: '160');
    if (saavnUrl != null && saavnUrl.isNotEmpty) {
      _urlCache[song.id] = _CachedUrl(saavnUrl);
      return saavnUrl;
    }

    // 3. Fallback to 96kbps match
    final lowBitrateUrl = await matchSaavnStream(song.title, song.artist, quality: '96');
    if (lowBitrateUrl != null && lowBitrateUrl.isNotEmpty) {
      _urlCache[song.id] = _CachedUrl(lowBitrateUrl);
      return lowBitrateUrl;
    }

    return null;
  }

  /// Match any track on JioSaavn by Title & Artist to obtain direct MP4 CDN URL
  static Future<String?> matchSaavnStream(String title, String artist, {String quality = '320'}) async {
    // Clean title of noise (e.g. "(Official Video)", "[4K]", "feat.", etc.)
    var cleanTitle = title
        .replaceAll(RegExp(r'\s*[\(\[][^\)\]]*(?:official|video|audio|lyric|remix|feat|ft\.|4k|hd|visualizer|prod\.)[^\)\]]*[\)\]]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\|.*$'), '')
        .replaceAll(RegExp(r'\s*-\s*(?:Official|Video|Audio|Lyrics|4K).*$', caseSensitive: false), '')
        .trim();

    var cleanArtist = artist.split(',').first.split('&').first.trim();

    // Check if artist is generic placeholder
    final isGenericArtist = cleanArtist.isEmpty ||
        cleanArtist.toLowerCase() == 'soundifly artist' ||
        cleanArtist.toLowerCase() == 'various artists' ||
        cleanArtist.toLowerCase() == 'top artist' ||
        cleanArtist.toLowerCase() == 'trending' ||
        cleanArtist.toLowerCase() == 'artist';

    // If title has "Artist - Song", separate them
    if (isGenericArtist && cleanTitle.contains(' - ')) {
      final parts = cleanTitle.split(' - ');
      cleanArtist = parts.first.trim();
      cleanTitle = parts.sublist(1).join(' - ').trim();
    }

    // Prepare search queries: primary with artist, secondary with title only
    final queries = <String>[];
    if (!isGenericArtist && cleanArtist.isNotEmpty) {
      queries.add('$cleanTitle $cleanArtist'.trim());
    }
    queries.add(cleanTitle.trim());

    for (final q in queries) {
      if (q.isEmpty) continue;
      try {
        final uri = Uri.parse(
          'https://www.jiosaavn.com/api.php?__call=search.getResults&_format=json&n=10&p=1&q=${Uri.encodeComponent(q)}',
        );
        final res = await http.get(uri, headers: _saavnHeaders).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final results = data['results'] as List? ?? [];
          final targetTitleNorm = _normalize(cleanTitle);
          final targetArtistNorm = isGenericArtist ? '' : _normalize(cleanArtist);

          for (final item in results) {
            if (item is! Map) continue;
            final songTitle = item['song']?.toString() ?? '';
            final primaryArtists = item['primary_artists']?.toString() ?? item['singers']?.toString() ?? '';

            final songTitleNorm = _normalize(songTitle);
            final primaryArtistsNorm = _normalize(primaryArtists);

            // Match title similarity
            final titleMatches = songTitleNorm.contains(targetTitleNorm) ||
                targetTitleNorm.contains(songTitleNorm) ||
                _wordOverlapRatio(songTitleNorm, targetTitleNorm) >= 0.7;

            // Match artist similarity (or allow if artist is generic or not specified)
            final artistMatches = targetArtistNorm.isEmpty ||
                primaryArtistsNorm.contains(targetArtistNorm) ||
                targetArtistNorm.contains(primaryArtistsNorm) ||
                _wordOverlapRatio(primaryArtistsNorm, targetArtistNorm) >= 0.5;

            if (titleMatches && artistMatches) {
              final enc = item['encrypted_media_url']?.toString() ??
                  item['more_info']?['encrypted_media_url']?.toString();
              final direct = decryptSaavnUrl(enc, quality: quality);
              if (direct != null && direct.isNotEmpty) {
                debugPrint('[AudioStreamResolver] Matched authorized Saavn stream (${quality}kbps) for "$title" -> $direct');
                return direct;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AudioStreamResolver] Saavn match note for "$q": $e');
      }
    }
    return null;
  }

  /// Resolve JioSaavn song by its ID via getDetails API
  static Future<String?> _resolveSaavnById(String songId, {String quality = '320'}) async {
    final cleanId = songId.replaceFirst('saavn_', '');
    try {
      final uri = Uri.parse('https://www.jiosaavn.com/api.php?__call=song.getDetails&pids=$cleanId&_format=json');
      final res = await http.get(uri, headers: _saavnHeaders).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map) {
          final item = data[cleanId] ?? (data.isNotEmpty ? data.values.first : null);
          if (item is Map) {
            final enc = item['encrypted_media_url']?.toString() ??
                item['more_info']?['encrypted_media_url']?.toString();
            final direct = decryptSaavnUrl(enc, quality: quality);
            if (direct != null && direct.isNotEmpty) {
              return direct;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioStreamResolver] Saavn ID resolve error: $e');
    }
    return null;
  }

  static bool _isDirectAudioUrl(String url) {
    if (url.isEmpty) return false;
    if (url.contains('/api/stream/')) return false;
    if (url.contains('/stream/')) return false;
    return url.contains('saavncdn.com') ||
        url.endsWith('.mp4') ||
        url.endsWith('.m4a') ||
        url.endsWith('.mp3');
  }

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static double _wordOverlapRatio(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final aWords = a.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final bWords = b.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    if (aWords.isEmpty || bWords.isEmpty) return 0.0;
    final intersection = aWords.intersection(bWords);
    return (2.0 * intersection.length) / (aWords.length + bWords.length);
  }
}

class _CachedUrl {
  final String url;
  final DateTime timestamp;

  _CachedUrl(this.url) : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > AudioStreamResolver._cacheExpiry;
}
