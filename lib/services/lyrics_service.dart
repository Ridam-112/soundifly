import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/lyrics_model.dart';
import '../config/api_config.dart';

class LyricsService {
  static String get _backendUrl => ApiConfig.lyricsUrl;
  static final Map<String, ParsedLyrics> _cache = {};

  static const Map<String, String> _headers = {
    'User-Agent': 'Soundifly-Music-App/1.0.0 (https://soundifly.onrender.com)',
    'Accept': 'application/json',
  };

  /// Clean song title for optimal search matching across lyrics databases
  static String cleanSongTitle(String title, [String? artist]) {
    var cleaned = title
        .replaceAll(RegExp(r'\(.*?(official|video|audio|lyric|remix|lofi|version|feat|ft|music video|full song|visualizer|live|teaser|from|ost|soundtrack).*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?(official|video|audio|lyric|remix|lofi|version|feat|ft|music video|full song|visualizer|live|teaser|from|ost|soundtrack).*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'-\s*(lofi|official|audio|remix|slowed|reverb|full video).*', caseSensitive: false), '')
        .replaceAll(RegExp(r'feat\..*', caseSensitive: false), '')
        .replaceAll(RegExp(r'ft\..*', caseSensitive: false), '')
        .trim();

    // If title has "Artist - Song", remove artist prefix if it matches
    if (cleaned.contains(' - ')) {
      final parts = cleaned.split(' - ');
      if (parts.length == 2) {
        if (artist != null && artist.isNotEmpty) {
          final artLower = artist.toLowerCase().trim();
          if (parts[0].toLowerCase().contains(artLower) || artLower.contains(parts[0].toLowerCase().trim())) {
            cleaned = parts[1].trim();
          } else if (parts[1].toLowerCase().contains(artLower) || artLower.contains(parts[1].toLowerCase().trim())) {
            cleaned = parts[0].trim();
          }
        }
      }
    }

    return cleaned.isNotEmpty ? cleaned : title.trim();
  }

  /// Clean artist name for better search matching
  static String cleanArtistName(String artist) {
    if (artist.isEmpty) return '';
    final primary = artist
        .replaceAll(RegExp(r'feat\..*', caseSensitive: false), '')
        .replaceAll(RegExp(r'ft\..*', caseSensitive: false), '')
        .split(RegExp(r'[,&/]'))
        .first
        .trim();
    return primary.isNotEmpty ? primary : artist.trim();
  }

  /// Checks if lyrics are dummy / placeholder lines
  static bool _isPlaceholderLyrics(List<LyricLine> lines) {
    if (lines.isEmpty) return true;
    for (final line in lines) {
      final text = line.text.toLowerCase();
      if (text.contains('streamed via') ||
          text.contains('soundifly engine') ||
          text.contains('searching lyrics') ||
          text.contains('now playing:')) {
        return true;
      }
    }
    return false;
  }

  /// Parse LRC time-synchronized lyric strings ([mm:ss.xx] Lyric text)
  static List<LyricLine> parseLrcString(String lrcText) {
    final lines = lrcText.split('\n');
    final List<LyricLine> result = [];
    final timestampRegex = RegExp(r'\[(\d+):(\d{2}(?:\.\d+)?)\]');

    for (final raw in lines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final matches = timestampRegex.allMatches(trimmed).toList();
      if (matches.isNotEmpty) {
        final text = trimmed.substring(matches.last.end).trim();
        if (text.isNotEmpty) {
          for (final m in matches) {
            final minutes = int.tryParse(m.group(1) ?? '0') ?? 0;
            final seconds = double.tryParse(m.group(2) ?? '0') ?? 0.0;
            final totalMillis = ((minutes * 60 + seconds) * 1000).toInt();
            result.add(LyricLine(
              timestamp: Duration(milliseconds: totalMillis),
              text: text,
            ));
          }
        }
      }
    }
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  /// Fetch time-synchronized or plain lyrics for [song]
  static Future<ParsedLyrics> getLyrics(Song song, {bool forceRefresh = false}) async {
    final cacheKey = '${song.id}::${song.title}::${song.artist}';
    if (!forceRefresh && _cache.containsKey(cacheKey) && _cache[cacheKey]!.lines.isNotEmpty) {
      debugPrint('[LyricsService] Using cached lyrics for "${song.title}"');
      return _cache[cacheKey]!;
    }

    // 1. Check if song already has genuine embedded lyrics in its model
    if (!forceRefresh && song.lyrics.isNotEmpty && !_isPlaceholderLyrics(song.lyrics)) {
      debugPrint('[LyricsService] Using genuine embedded lyrics for "${song.title}"');
      final parsed = ParsedLyrics(
        isSynced: true,
        lines: song.lyrics,
        source: 'Embedded Metadata',
      );
      _cache[cacheKey] = parsed;
      return parsed;
    }

    final cleanedTitle = cleanSongTitle(song.title, song.artist);
    final cleanedArtist = cleanArtistName(song.artist);
    final durationSeconds = song.duration.inSeconds;

    debugPrint('[LyricsService] Requesting lyrics for "$cleanedTitle" by "$cleanedArtist" (dur: ${durationSeconds}s, original: "${song.title}")');

    // 2. High Priority: Direct LRCLIB Database Query (ultra-fast, zero auth, supports Bengali & all global languages)
    try {
      final lrclibLyrics = await _fetchFromLrcLib(cleanedTitle, cleanedArtist, durationSeconds);
      if (lrclibLyrics != null && lrclibLyrics.lines.isNotEmpty) {
        debugPrint('[LyricsService] Successfully resolved lyrics from LRCLIB (${lrclibLyrics.lines.length} lines, synced: ${lrclibLyrics.isSynced})');
        _cache[cacheKey] = lrclibLyrics;
        return lrclibLyrics;
      }
    } catch (e) {
      debugPrint('[LyricsService] LRCLIB direct fetch exception: $e');
    }

    // 3. Fallback: Secondary LRCLIB query using raw song title if cleaned title differed
    if (cleanedTitle != song.title.trim()) {
      try {
        final fallbackLrc = await _fetchFromLrcLib(song.title.trim(), '', durationSeconds);
        if (fallbackLrc != null && fallbackLrc.lines.isNotEmpty) {
          debugPrint('[LyricsService] Resolved lyrics via raw title LRCLIB query (${fallbackLrc.lines.length} lines)');
          _cache[cacheKey] = fallbackLrc;
          return fallbackLrc;
        }
      } catch (e) {
        debugPrint('[LyricsService] Raw title LRCLIB exception: $e');
      }
    }

    // 4. Cloud Backend: Soundifly Node Engine (/api/lyrics)
    try {
      final uri = Uri.parse(
        '$_backendUrl?title=${Uri.encodeComponent(cleanedTitle)}&artist=${Uri.encodeComponent(cleanedArtist)}${durationSeconds > 0 ? "&duration=$durationSeconds" : ""}',
      );
      debugPrint('[LyricsService] Cloud backend query: $uri');

      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(const Duration(seconds: 12));

      debugPrint('[LyricsService] Backend response code: ${response.statusCode}');

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

        if (parsedLines.isNotEmpty && !_isPlaceholderLyrics(parsedLines)) {
          debugPrint('[LyricsService] Cloud backend delivered ${parsedLines.length} lines');
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
      debugPrint('[LyricsService] Soundifly Cloud Backend lyrics error: $e');
    }

    debugPrint('[LyricsService] No lyrics found anywhere for "${song.title}"');
    return ParsedLyrics.empty;
  }

  /// Directly queries LRCLIB API with exact get and search fallback
  static Future<ParsedLyrics?> _fetchFromLrcLib(String title, String artist, int durationSeconds) async {
    // 1. Try exact match via /api/get
    if (title.isNotEmpty && artist.isNotEmpty) {
      try {
        final durParam = durationSeconds > 0 ? '&duration=$durationSeconds' : '';
        final getUri = Uri.parse(
          'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(title)}&artist_name=${Uri.encodeComponent(artist)}$durParam',
        );
        debugPrint('[LyricsService] Querying LRCLIB exact: $getUri');

        final res = await http.get(getUri, headers: _headers).timeout(const Duration(seconds: 4));
        debugPrint('[LyricsService] LRCLIB exact response status: ${res.statusCode}');

        if (res.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            final lyrics = _extractFromLrcLibItem(decoded, durationSeconds);
            if (lyrics != null && lyrics.lines.isNotEmpty) {
              return lyrics;
            }
          }
        }
      } catch (e) {
        debugPrint('[LyricsService] LRCLIB exact lookup error: $e');
      }
    }

    // 2. Try search query via /api/search
    try {
      final query = artist.isNotEmpty ? '$title $artist' : title;
      final searchUri = Uri.parse('https://lrclib.net/api/search?q=${Uri.encodeComponent(query)}');
      debugPrint('[LyricsService] Querying LRCLIB search: $searchUri');

      final res = await http.get(searchUri, headers: _headers).timeout(const Duration(seconds: 5));
      debugPrint('[LyricsService] LRCLIB search response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is List && decoded.isNotEmpty) {
          // Priority 1: Check for item with syncedLyrics
          for (final raw in decoded) {
            if (raw is Map<String, dynamic>) {
              final synced = raw['syncedLyrics'] as String?;
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
            }
          }

          // Priority 2: Check for item with plainLyrics
          for (final raw in decoded) {
            if (raw is Map<String, dynamic>) {
              final plain = raw['plainLyrics'] as String?;
              if (plain != null && plain.trim().isNotEmpty) {
                final lyrics = _buildPlainLyrics(plain, durationSeconds);
                if (lyrics.lines.isNotEmpty) {
                  return lyrics;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LyricsService] LRCLIB search error: $e');
    }

    return null;
  }

  static ParsedLyrics? _extractFromLrcLibItem(Map<String, dynamic> item, int durationSeconds) {
    final synced = item['syncedLyrics'] as String?;
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

    final plain = item['plainLyrics'] as String?;
    if (plain != null && plain.trim().isNotEmpty) {
      return _buildPlainLyrics(plain, durationSeconds);
    }

    return null;
  }

  static ParsedLyrics _buildPlainLyrics(String plain, int durationSeconds) {
    final rawLines = plain
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.contains(''))
        .toList();

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

  /// Clear the lyrics cache
  static void clearCache() {
    _cache.clear();
  }
}
