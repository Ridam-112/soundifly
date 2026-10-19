import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'supabase_service.dart';

class FavoriteSongItem {
  final Song song;
  final DateTime likedAt;

  FavoriteSongItem({required this.song, required this.likedAt});
}

class SupabaseMusicSyncService {
  /// Asynchronously log song play to user's listening history
  static Future<void> recordListeningHistory(Song song) async {
    if (!SupabaseService.isInitialized) return;

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      await SupabaseService.client.from('listening_history').insert({
        'user_id': user.id,
        'song_id': song.id,
        'title': song.title,
        'artist': song.artist,
        'cover_url': song.coverUrl,
        'duration_seconds': song.duration.inSeconds,
      });
    } catch (e) {
      // Never throw or interrupt playback on network/schema error
      debugPrint('Note: Supabase listening history recording skipped: $e');
    }
  }

  /// Sync user like/unlike status to Supabase PostgreSQL
  static Future<void> syncFavorite(Song song, bool isLiked) async {
    if (!SupabaseService.isInitialized) return;

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      if (isLiked) {
        await SupabaseService.client.from('user_favorites').upsert({
          'user_id': user.id,
          'song_id': song.id,
          'title': song.title,
          'artist': song.artist,
          'cover_url': song.coverUrl,
          'duration_seconds': song.duration.inSeconds,
        });
      } else {
        await SupabaseService.client
            .from('user_favorites')
            .delete()
            .match({'user_id': user.id, 'song_id': song.id});
      }
    } catch (e) {
      debugPrint('Note: Supabase favorites sync skipped: $e');
    }
  }

  /// Fetch user favorite song IDs on login
  static Future<List<String>> fetchUserFavoriteIds() async {
    if (!SupabaseService.isInitialized) return [];

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return [];

      final List<dynamic> data = await SupabaseService.client
          .from('user_favorites')
          .select('song_id')
          .eq('user_id', user.id);

      return data.map((item) => item['song_id'].toString()).toList();
    } catch (e) {
      debugPrint('Note: Supabase favorites fetch skipped: $e');
      return [];
    }
  }

  /// Fetch all favorite songs with timestamp for full restoration and sorting
  static Future<List<FavoriteSongItem>> fetchUserFavoriteSongs() async {
    if (!SupabaseService.isInitialized) return [];

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return [];

      final List<dynamic> data = await SupabaseService.client
          .from('user_favorites')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return data.map((item) {
        final song = Song(
          id: item['song_id'].toString(),
          title: item['title']?.toString() ?? '',
          artist: item['artist']?.toString() ?? '',
          album: '',
          coverUrl: item['cover_url']?.toString() ?? '',
          audioUrl: '', // resolved on playback
          duration: Duration(seconds: (item['duration_seconds'] as num?)?.toInt() ?? 0),
        );
        final likedAt = item['created_at'] != null
            ? DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now()
            : DateTime.now();

        return FavoriteSongItem(song: song, likedAt: likedAt);
      }).toList();
    } catch (e) {
      debugPrint('Note: Supabase favorites full fetch skipped: $e');
      return [];
    }
  }
}
