import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dart_des/dart_des.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

class AudioStreamResolver {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, _CachedUrl> _urlCache = {};
  static final List<int> _saavnDesKey = utf8.encode('38346591');

  // Cache entries expire after 3 hours (YouTube stream URLs expire ~6h)
  static const Duration _cacheExpiry = Duration(hours: 3);

  static const Map<String, String> _saavnHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  /// Decrypts JioSaavn encrypted media url into direct 320kbps MP4 CDN URL
  static String? decryptSaavnUrl(String? encryptedMediaUrl) {
    if (encryptedMediaUrl == null || encryptedMediaUrl.trim().isEmpty) return null;
    try {
      final encryptedBytes = base64.decode(encryptedMediaUrl.trim());
      final des = DES(key: _saavnDesKey, mode: DESMode.ECB, paddingType: DESPaddingType.PKCS7);
      final decryptedBytes = des.decrypt(encryptedBytes);
      final rawUrl = utf8.decode(decryptedBytes);
      if (rawUrl.isEmpty) return null;
      return rawUrl.replaceAll('_96.mp4', '_320.mp4');
    } catch (e) {
      debugPrint('[AudioStreamResolver] Saavn decrypt error: $e');
      return null;
    }
  }

  /// Resolves the fastest direct playable CDN audio URL for any song.
  /// Priority order:
  /// 1. Already-direct CDN URLs (instant)
  /// 2. In-memory cache (instant)
  /// 3. YouTube video ID -> on-device extraction via YouTubeExplode (prefer M4A/AAC, 10s timeout)
  /// 4. Resilient Fallback: JioSaavn strict match (>= 0.75 token similarity, keeps Royaa Main distinct)
  /// 5. JioSaavn DES decrypt for saavn_ IDs (instant, 320kbps AAC)
  /// 6. Original URL fallback
  static Future<String> resolveStreamUrl(Song song) async {
    final rawUrl = song.audioUrl.trim();

    // 1. If song.audioUrl is already a direct playable CDN audio URL
    if (_isDirectAudioUrl(rawUrl)) {
      return rawUrl;
    }

    // 2. Check in-memory cache (with expiry)
    final cached = _urlCache[song.id];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    // 3. If it's a YouTube video ID — resolve the EXACT YouTube stream
    final isYtId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(song.id);
    if (isYtId) {
      final ytResolved = await _resolveYouTube(song.id);
      if (ytResolved != null && ytResolved.isNotEmpty) {
        return ytResolved;
      }

      // If YouTube direct extraction timed out or was throttled on mobile carrier,
      // fallback to strict title+artist matching on JioSaavn (320kbps)
      final saavnMatch = await _resolveSaavnStrictMatch(song);
      if (saavnMatch != null && saavnMatch.isNotEmpty) {
        return saavnMatch;
      }
    }

    // 4. If it's a JioSaavn song ID — instant DES decrypt
    if (song.id.startsWith('saavn_')) {
      final resolved = await _resolveSaavnById(song.id);
      if (resolved != null) return resolved;
    }

    // 5. Strict Saavn matching fallback for any track
    final saavnMatch = await _resolveSaavnStrictMatch(song);
    if (saavnMatch != null && saavnMatch.isNotEmpty) {
      return saavnMatch;
    }

    // 6. Return rawUrl if nothing else succeeded
    debugPrint('[AudioStreamResolver] All resolvers failed for ${song.id}, using rawUrl');
    return rawUrl;
  }

  /// Resolve JioSaavn song by its ID via getDetails API
  static Future<String?> _resolveSaavnById(String songId) async {
    final cleanId = songId.replaceFirst('saavn_', '');
    try {
      final uri = Uri.parse('https://www.jiosaavn.com/api.php?__call=song.getDetails&pids=$cleanId&_format=json');
      final res = await http.get(uri, headers: _saavnHeaders).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map) {
          // Try exact ID key first, then first key
          final item = data[cleanId] ?? (data.isNotEmpty ? data.values.first : null);
          if (item is Map) {
            final enc = item['encrypted_media_url']?.toString();
            final direct = decryptSaavnUrl(enc);
            if (direct != null && direct.isNotEmpty) {
              _urlCache[songId] = _CachedUrl(direct);
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

  /// Helper to normalize strings for robust fuzzy-proof matching
  static String _normalizeTitle(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove (Official Video), (From ...), (Audio)
        .replaceAll(RegExp(r'\[.*?\]'), '') // Remove [Lofi], [Remix]
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Checks if two tokens represent the same word (e.g., phonetic variants of roya/royaa/royaan)
  static bool _wordsMatch(String w1, String w2) {
    if (w1 == w2) return true;
    const royaVariants = {'roya', 'royaa', 'royaan'};
    if (royaVariants.contains(w1) && royaVariants.contains(w2)) return true;
    return false;
  }

  /// Strict token-overlap similarity between two titles (0.0 to 1.0)
  static double _computeSimilarity(String a, String b) {
    final normA = _normalizeTitle(a);
    final normB = _normalizeTitle(b);
    if (normA.isEmpty || normB.isEmpty) return 0.0;
    if (normA == normB) return 1.0;

    final tokensA = normA.split(' ').where((s) => s.isNotEmpty).toList();
    final tokensB = normB.split(' ').where((s) => s.isNotEmpty).toList();
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;

    int matches = 0;
    for (final t in tokensA) {
      if (tokensB.any((u) => _wordsMatch(t, u))) {
        matches++;
      }
    }
    return matches / (tokensA.length > tokensB.length ? tokensA.length : tokensB.length);
  }

  /// Search JioSaavn and only accept tracks with strict token match (>= 0.75 similarity).
  /// This ensures "Royaa Main" will match "Main Royaan" (100% token overlap)
  /// and NEVER match "Maine Royaan" (50% overlap, strictly rejected).
  static Future<String?> _resolveSaavnStrictMatch(Song song) async {
    try {
      final searchQ = '${song.title} ${song.artist}'.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (searchQ.length < 2) return null;
      final uri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getResults&_format=json&n=10&p=1&q=${Uri.encodeComponent(searchQ)}',
      );
      final res = await http.get(uri, headers: _saavnHeaders).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = data['results'] as List? ?? [];
        for (final item in list) {
          if (item is! Map) continue;
          final saavnTitle = (item['song'] ?? item['title'] ?? '').toString();
          final saavnArtist = (item['primary_artists'] ?? item['singers'] ?? '').toString();

          final sim = _computeSimilarity(song.title, saavnTitle);
          if (sim >= 0.75) {
            // Also check artist overlap if both are present
            if (song.artist.isNotEmpty && saavnArtist.isNotEmpty) {
              final artistSim = _computeSimilarity(song.artist, saavnArtist);
              if (artistSim < 0.25) continue; // Different artist, reject
            }

            final enc = item['encrypted_media_url']?.toString();
            final direct = decryptSaavnUrl(enc);
            if (direct != null && direct.isNotEmpty) {
              debugPrint('[AudioStreamResolver] Strict Saavn match (${(sim * 100).toInt()}%): "$saavnTitle" for "${song.title}"');
              _urlCache[song.id] = _CachedUrl(direct);
              return direct;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioStreamResolver] Saavn strict search error: $e');
    }
    return null;
  }

  /// Extract YouTube audio stream on-device, preferring M4A/AAC (universal) over webm/opus
  static Future<String?> _resolveYouTube(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 10));
      final audioStreams = manifest.audioOnly.toList();

      if (audioStreams.isEmpty) return null;

      // Prefer M4A/MP4/AAC streams — these play on ALL Android devices without ExoPlayer
      final m4aStreams = audioStreams.where(
        (s) => s.container.name == 'mp4' || 
               s.container.name == 'm4a' || 
               s.audioCodec.contains('mp4a') || 
               s.audioCodec.contains('aac'),
      ).toList();

      String directUrl;
      if (m4aStreams.isNotEmpty) {
        // Sort by bitrate descending, pick highest quality M4A
        m4aStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        directUrl = m4aStreams.first.url.toString();
        debugPrint('[AudioStreamResolver] YouTube M4A stream: ${m4aStreams.first.bitrate}bps ${m4aStreams.first.audioCodec}');
      } else {
        // Fallback to highest bitrate of any format (webm/opus) — works with ExoPlayer
        final best = audioStreams.toList()..sort((a, b) => b.bitrate.compareTo(a.bitrate));
        directUrl = best.first.url.toString();
        debugPrint('[AudioStreamResolver] YouTube fallback stream: ${best.first.bitrate}bps ${best.first.audioCodec}');
      }

      if (directUrl.isNotEmpty) {
        _urlCache[videoId] = _CachedUrl(directUrl);
        return directUrl;
      }
    } catch (e) {
      debugPrint('[AudioStreamResolver] YouTubeExplode error: $e');
    }
    return null;
  }

  static bool _isDirectAudioUrl(String url) {
    if (url.isEmpty) return false;
    if (url.contains('/api/stream/')) return false;
    return url.contains('saavncdn.com') ||
        url.contains('googlevideo.com') ||
        url.endsWith('.mp4') ||
        url.endsWith('.m4a') ||
        url.endsWith('.mp3');
  }
}

class _CachedUrl {
  final String url;
  final DateTime timestamp;

  _CachedUrl(this.url) : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > AudioStreamResolver._cacheExpiry;
}
