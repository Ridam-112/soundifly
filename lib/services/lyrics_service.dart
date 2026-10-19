import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/lyrics_model.dart';
import '../config/api_config.dart';

class LyricsService {
  static String get _backendUrl => ApiConfig.lyricsUrl;
  static final Map<String, ParsedLyrics> _cache = {};

  /// Fetch time-synchronized or plain lyrics for [song]
  static Future<ParsedLyrics> getLyrics(Song song) async {
    final cacheKey = '${song.id}::${song.title}::${song.artist}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 1. Check if song already has embedded lyrics in its model
    if (song.lyrics.isNotEmpty) {
      final parsed = ParsedLyrics(
        isSynced: true,
        lines: song.lyrics,
        source: 'Embedded Metadata',
      );
      _cache[cacheKey] = parsed;
      return parsed;
    }

    // 2. Query our authorized Soundifly Node backend lyrics API
    try {
      final durSeconds = song.duration.inSeconds;
      final uri = Uri.parse(
        '$_backendUrl?title=${Uri.encodeComponent(song.title)}&artist=${Uri.encodeComponent(song.artist)}${durSeconds > 0 ? "&duration=$durSeconds" : ""}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool isSynced = data['synced'] as bool? ?? false;
        final String source = data['source'] as String? ?? 'LRCLIB';
        final List rawLines = data['lines'] as List? ?? [];

        final List<LyricLine> parsedLines = [];
        for (final item in rawLines) {
          if (item is Map) {
            final int secs = (item['seconds'] as num?)?.toInt() ?? 0;
            final String text = (item['text'] as String?)?.trim() ?? '';
            if (text.isNotEmpty) {
              parsedLines.add(LyricLine(
                timestamp: Duration(seconds: secs),
                text: text,
              ));
            }
          }
        }

        if (parsedLines.isNotEmpty) {
          final result = ParsedLyrics(
            isSynced: isSynced,
            lines: parsedLines,
            source: source,
          );
          _cache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('Lyrics fetch note: $e');
    }

    // 3. Fallback: Friendly display line
    final fallback = ParsedLyrics(
      isSynced: false,
      lines: [
        LyricLine(timestamp: const Duration(seconds: 0), text: '♪ Playing ${song.title} ♪'),
        LyricLine(timestamp: const Duration(seconds: 8), text: song.artist),
        LyricLine(timestamp: const Duration(seconds: 16), text: 'No synchronized lyrics available for this track'),
      ],
      source: 'Soundifly Fallback',
    );
    _cache[cacheKey] = fallback;
    return fallback;
  }

  /// Clear the lyrics cache
  static void clearCache() {
    _cache.clear();
  }
}
