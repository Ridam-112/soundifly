import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../data/music_onboarding_data.dart';

class ArtistDiscoveryService {
  static final Map<String, List<OnboardingArtist>> _searchCache = {};

  /// Searches the curated catalogue + live artist discovery engine
  static Future<List<OnboardingArtist>> searchArtists(
    String query, {
    List<String>? preferredLanguages,
  }) async {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) {
      return MusicOnboardingData.getArtistsForLanguages(preferredLanguages ?? []);
    }

    if (_searchCache.containsKey(cleanQ)) {
      return _searchCache[cleanQ]!;
    }

    final List<OnboardingArtist> combined = [];
    final Set<String> seenNames = {};

    // 1. First Pass: Local curated catalogue matches
    for (final artist in MusicOnboardingData.curatedArtists) {
      if (artist.matchesQuery(cleanQ)) {
        seenNames.add(artist.name.toLowerCase());
        combined.add(artist);
      }
    }

    // 2. Second Pass: Live Cloud Discovery API
    try {
      final backendUri = Uri.parse(
        '${ApiConfig.baseUrl}/artists/search?q=${Uri.encodeComponent(cleanQ)}',
      );
      final res = await http.get(backendUri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        for (final item in data) {
          if (item is Map) {
            final name = (item['name'] as String?)?.trim() ?? '';
            final lower = name.toLowerCase();
            if (name.isEmpty || seenNames.contains(lower)) continue;
            seenNames.add(lower);

            final img = (item['imageUrl'] as String?) ?? '';
            final pop = (item['popularity'] as num?)?.toInt() ?? 1000;
            final typeStr = (item['artistType'] as String?) ?? 'Singer';
            final source = (item['imageSource'] as String?) ?? 'Live Artist Engine';

            combined.add(OnboardingArtist(
              id: item['id']?.toString() ?? 'live_${name.hashCode}',
              name: name,
              languages: preferredLanguages ?? ['Universal'],
              genre: typeStr,
              imageUrl: img,
              popularityScore: pop,
              isVerifiedImage: img.isNotEmpty && !img.contains('default-film'),
              imageSource: source,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[ArtistDiscoveryService] Backend search note: $e');
      // Direct fast fallback to JioSaavn API if backend server is sleeping
      try {
        final saavnUri = Uri.parse(
          'https://www.jiosaavn.com/api.php?__call=search.getArtistResults&_format=json&n=12&p=1&q=${Uri.encodeComponent(cleanQ)}',
        );
        final saavnRes = await http.get(saavnUri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 3));
        if (saavnRes.statusCode == 200) {
          final sData = jsonDecode(utf8.decode(saavnRes.bodyBytes));
          final list = sData['results'] as List? ?? [];
          for (final item in list) {
            if (item is Map) {
              final rawName = (item['name'] as String?) ?? '';
              final name = rawName
                  .replaceAll('&quot;', '"')
                  .replaceAll('&#039;', "'")
                  .replaceAll('&amp;', '&')
                  .trim();
              final lower = name.toLowerCase();
              if (name.isEmpty || seenNames.contains(lower)) continue;
              seenNames.add(lower);

              final rawImg = (item['image'] as String?) ?? '';
              final img = (rawImg.isNotEmpty && !rawImg.contains('default-film'))
                  ? rawImg.replaceAll('50x50', '500x500').replaceAll('150x150', '500x500')
                  : '';

              combined.add(OnboardingArtist(
                id: 'saavn_${item['id']}',
                name: name,
                languages: preferredLanguages ?? ['Universal'],
                genre: (item['role'] as String?) ?? 'Singer',
                imageUrl: img,
                popularityScore: (item['ctr'] as num?)?.toInt() ?? 500,
                isVerifiedImage: img.isNotEmpty,
                imageSource: 'JioSaavn Official CDN',
              ));
            }
          }
        }
      } catch (err2) {
        debugPrint('[ArtistDiscoveryService] Direct fallback note: $err2');
      }
    }

    // Sort: curated artists first, then by popularityScore descending
    combined.sort((a, b) {
      if (a.isVerifiedImage && !b.isVerifiedImage) return -1;
      if (!a.isVerifiedImage && b.isVerifiedImage) return 1;
      return b.popularityScore.compareTo(a.popularityScore);
    });

    _searchCache[cleanQ] = combined;
    return combined;
  }

  static void clearCache() {
    _searchCache.clear();
  }
}
