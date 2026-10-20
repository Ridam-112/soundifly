import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/lyrics_model.dart';
import '../config/api_config.dart';

class LyricsService {
  static String get _backendUrl => ApiConfig.lyricsUrl;
  static final Map<String, ParsedLyrics> _cache = {};

  /// Clean song title for better search matching
  static String cleanSongTitle(String title) {
    var cleaned = title
        .replaceAll(RegExp(r'\(.*?(official|video|audio|lyric|remix|lofi|version|feat|ft).*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?(official|video|audio|lyric|remix|lofi|version|feat|ft).*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'-\s*(lofi|official|audio|remix|slowed|reverb).*', caseSensitive: false), '')
        .replaceAll(RegExp(r'feat\..*', caseSensitive: false), '')
        .replaceAll(RegExp(r'ft\..*', caseSensitive: false), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : title.trim();
  }

  /// Clean artist name for better search matching
  static String cleanArtistName(String artist) {
    if (artist.isEmpty) return '';
    final primary = artist.split(RegExp(r'[,&/]')).first.trim();
    return primary.isNotEmpty ? primary : artist.trim();
  }

  /// Parse LRC time-synchronized lyric strings ([mm:ss.xx] Lyric text)
  static List<LyricLine> parseLrcString(String lrcText) {
    final lines = lrcText.split('\n');
    final List<LyricLine> result = [];
    final regex = RegExp(r'\[(\d{2}):(\d{2}(?:\.\d+)?)\](.*)');

    for (final raw in lines) {
      final match = regex.firstMatch(raw.trim());
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = double.tryParse(match.group(2) ?? '0') ?? 0.0;
        final text = (match.group(3) ?? '').trim();
        final totalMillis = ((minutes * 60 + seconds) * 1000).toInt();
        if (text.isNotEmpty) {
          result.add(LyricLine(
            timestamp: Duration(milliseconds: totalMillis),
            text: text,
          ));
        }
      }
    }
    return result;
  }

  /// Fetch time-synchronized or plain lyrics for [song]
  static Future<ParsedLyrics> getLyrics(Song song, {bool forceRefresh = false}) async {
    final cacheKey = '${song.id}::${song.title}::${song.artist}';
    if (!forceRefresh && _cache.containsKey(cacheKey) && _cache[cacheKey]!.lines.isNotEmpty) {
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

    final cleanedTitle = cleanSongTitle(song.title);
    final cleanedArtist = cleanArtistName(song.artist);

    // 2. High Priority: Direct LRCLIB Database Query (ultra-fast, zero auth, supports Bengali & all languages)
    try {
      final lrclibLyrics = await _fetchFromLrcLib(cleanedTitle, cleanedArtist, song.duration.inSeconds);
      if (lrclibLyrics != null && lrclibLyrics.lines.isNotEmpty) {
        _cache[cacheKey] = lrclibLyrics;
        return lrclibLyrics;
      }
    } catch (e) {
      debugPrint('LRCLIB direct fetch note: $e');
    }

    // 3. Cloud Backend: Soundifly Node Engine (/api/lyrics) with full 14s timeout
    try {
      final durSeconds = song.duration.inSeconds;
      final uri = Uri.parse(
        '$_backendUrl?title=${Uri.encodeComponent(cleanedTitle)}&artist=${Uri.encodeComponent(cleanedArtist)}${durSeconds > 0 ? "&duration=$durSeconds" : ""}',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 14));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final bool isSynced = data['synced'] as bool? ?? false;
        final String source = data['source'] as String? ?? 'Soundifly Engine';
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
      debugPrint('Soundifly Cloud Backend lyrics error: $e');
    }

    // 4. Secondary fallback: Query LRCLIB with raw song title
    if (cleanedTitle != song.title.trim()) {
      try {
        final fallbackLrc = await _fetchFromLrcLib(song.title.trim(), '', song.duration.inSeconds);
        if (fallbackLrc != null && fallbackLrc.lines.isNotEmpty) {
          _cache[cacheKey] = fallbackLrc;
          return fallbackLrc;
        }
      } catch (_) {}
    }

    // 5. Temporary fallback display (DO NOT CACHE permanently, allows retry)
    return ParsedLyrics(
      isSynced: false,
      lines: [
        LyricLine(timestamp: const Duration(seconds: 0), text: '♪ ${song.title} ♪'),
        LyricLine(timestamp: const Duration(seconds: 8), text: song.artist),
        LyricLine(timestamp: const Duration(seconds: 18), text: 'Searching lyrics for this track...'),
      ],
      source: 'Soundifly Real-time Sync',
    );
  }

  /// Directly queries LRCLIB API with search and exact match
  static Future<ParsedLyrics?> _fetchFromLrcLib(String title, String artist, int durationSeconds) async {
    // 1. Try search query
    final query = artist.isNotEmpty ? '$title $artist' : title;
    final searchUri = Uri.parse('https://lrclib.net/api/search?q=${Uri.encodeComponent(query)}');

    final res = await http.get(
      searchUri,
      headers: {'User-Agent': 'Soundifly-Music-App/1.0.0 (https://soundifly.onrender.com)'},
    ).timeout(const Duration(seconds: 6));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is List && decoded.isNotEmpty) {
        final item = decoded.first as Map<String, dynamic>;
        final synced = item['syncedLyrics'] as String?;
        final plain = item['plainLyrics'] as String?;

        if (synced != null && synced.trim().isNotEmpty) {
          final parsed = parseLrcString(synced);
          if (parsed.isNotEmpty) {
            return ParsedLyrics(
              isSynced: true,
              lines: parsed,
              source: 'LRCLIB (Synced)',
            );
          }
        }

        if (plain != null && plain.trim().isNotEmpty) {
          final rawLines = plain.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
          final totalDur = durationSeconds > 0 ? durationSeconds : 210;
          final step = rawLines.isNotEmpty ? (totalDur / rawLines.length).clamp(3.0, 8.0) : 4.0;
          final lines = <LyricLine>[];
          for (int i = 0; i < rawLines.length; i++) {
            lines.add(LyricLine(
              timestamp: Duration(milliseconds: (i * step * 1000).toInt()),
              text: rawLines[i],
            ));
          }
          return ParsedLyrics(
            isSynced: false,
            lines: lines,
            source: 'LRCLIB (Plain)',
          );
        }
      }
    }
    return null;
  }

  /// Clear the lyrics cache
  static void clearCache() {
    _cache.clear();
  }
}
