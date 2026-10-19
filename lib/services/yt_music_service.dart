import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../data/mock_data.dart';
import '../config/api_config.dart';

class YTMusicService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Song>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((item) => _parseSong(item)).toList();
      }
    } catch (e) {
      // Graceful local fallback if offline
      return MockData.allSongs.where((s) {
        final q = query.toLowerCase();
        return s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q);
      }).toList();
    }
    return [];
  }

  static Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/suggestions?q=${Uri.encodeComponent(query)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((s) => s.toString()).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  static Future<List<Song>> getTrending() async {
    try {
      final uri = Uri.parse('$baseUrl/trending');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final songs = data.map((item) => _parseSong(item)).toList();
        if (songs.isNotEmpty) return songs;
      }
    } catch (e) {
      // Return initial defaults
      return MockData.allSongs;
    }
    return MockData.allSongs;
  }

  static Future<List<LyricLine>> getLyrics(String title, String artist, {int? durationSeconds}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/lyrics?title=${Uri.encodeComponent(title)}&artist=${Uri.encodeComponent(artist)}${durationSeconds != null ? "&duration=$durationSeconds" : ""}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List lines = data['lines'] ?? [];
        return lines.map((l) {
          final int secs = l['seconds'] ?? 0;
          final String text = l['text'] ?? '';
          return LyricLine(timestamp: Duration(seconds: secs), text: text);
        }).toList();
      }
    } catch (e) {
      // Ignore on timeout or error
    }
    return [];
  }

  static Song _parseSong(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? 'yt_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'Unknown Track',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Single',
      coverUrl: json['coverUrl'] ?? 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      audioUrl: json['audioUrl'] ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: Duration(seconds: json['durationSeconds'] ?? 210),
      genre: json['genre'] ?? 'Soundifly Stream',
      releaseYear: '2026',
      lyrics: [
        LyricLine(timestamp: const Duration(seconds: 5), text: "Streamed via Soundifly Cloud Engine"),
        LyricLine(timestamp: const Duration(seconds: 15), text: "Streamed via Soundifly Engine"),
        LyricLine(timestamp: const Duration(seconds: 30), text: "Enjoy the music together ❤️"),
      ],
    );
  }
}
