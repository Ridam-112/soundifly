import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import 'supabase_service.dart';

class SupabaseUserService {
  static SupabaseClient get _client => SupabaseService.client;
  static bool get _isReady => SupabaseService.isInitialized;

  // ===========================================================================
  // 1. User Profile Management
  // ===========================================================================

  static Future<UserProfile?> fetchProfile(String userId, {String email = ''}) async {
    if (!_isReady) return null;

    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;
      return UserProfile.fromMap(res, email: email);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  static Future<bool> checkUsernameAvailable(String username, {String? excludeUserId}) async {
    if (!_isReady) return true;
    final normalized = username.trim().toLowerCase();

    try {
      var query = _client
          .from('profiles')
          .select('id')
          .eq('username', normalized);

      if (excludeUserId != null) {
        query = query.neq('id', excludeUserId);
      }

      final List<dynamic> res = await query;
      return res.isEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return true;
    }
  }

  static Future<bool> updateProfile(UserProfile profile) async {
    if (!_isReady) return false;

    try {
      await _client.from('profiles').upsert(profile.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  static Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    if (!_isReady) return null;

    try {
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$extension',
            ),
          );

      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar to Supabase Storage: $e');
      return null;
    }
  }

  // ===========================================================================
  // 2. Playlist CRUD & Ordering
  // ===========================================================================

  static Future<List<Playlist>> fetchUserPlaylists(String userId) async {
    if (!_isReady) return [];

    try {
      final List<dynamic> playlistRows = await _client
          .from('playlists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Playlist> playlists = [];

      for (final pRow in playlistRows) {
        final pId = pRow['id'].toString();
        final List<dynamic> trackRows = await _client
            .from('playlist_tracks')
            .select()
            .eq('playlist_id', pId)
            .order('position', ascending: true);

        final songs = trackRows.map((t) => Song(
              id: t['song_id'].toString(),
              title: t['title']?.toString() ?? '',
              artist: t['artist']?.toString() ?? '',
              album: '',
              coverUrl: t['cover_url']?.toString() ?? '',
              audioUrl: t['audio_url']?.toString() ?? '',
              duration: Duration(seconds: (t['duration_seconds'] as num?)?.toInt() ?? 0),
            )).toList();

        playlists.add(Playlist.fromMap(pRow, songs: songs, currentUserId: userId));
      }

      return playlists;
    } catch (e) {
      debugPrint('Error fetching user playlists: $e');
      return [];
    }
  }

  static Future<Playlist?> createPlaylist(Playlist playlist) async {
    if (!_isReady) return playlist;

    try {
      final user = _client.auth.currentUser;
      if (user == null) return playlist;

      final insertData = {
        'user_id': user.id,
        'title': playlist.title,
        'description': playlist.description,
        'cover_url': playlist.coverUrl,
        'is_public': playlist.isPublic,
      };

      final res = await _client.from('playlists').insert(insertData).select().single();
      return Playlist.fromMap(res, songs: [], currentUserId: user.id);
    } catch (e) {
      debugPrint('Error creating playlist in Supabase: $e');
      return playlist;
    }
  }

  static Future<bool> updatePlaylist(Playlist playlist) async {
    if (!_isReady) return true;

    try {
      await _client.from('playlists').update({
        'title': playlist.title,
        'description': playlist.description,
        'cover_url': playlist.coverUrl,
        'is_public': playlist.isPublic,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', playlist.id);

      return true;
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      return false;
    }
  }

  static Future<bool> deletePlaylist(String playlistId) async {
    if (!_isReady) return true;

    try {
      await _client.from('playlists').delete().eq('id', playlistId);
      return true;
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      return false;
    }
  }

  static Future<bool> addTrackToPlaylist({
    required String playlistId,
    required Song song,
    required int position,
  }) async {
    if (!_isReady) return true;

    try {
      await _client.from('playlist_tracks').upsert({
        'playlist_id': playlistId,
        'song_id': song.id,
        'title': song.title,
        'artist': song.artist,
        'cover_url': song.coverUrl,
        'duration_seconds': song.duration.inSeconds,
        'audio_url': song.audioUrl,
        'position': position,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding track to playlist: $e');
      return false;
    }
  }

  static Future<bool> removeTrackFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    if (!_isReady) return true;

    try {
      await _client
          .from('playlist_tracks')
          .delete()
          .match({'playlist_id': playlistId, 'song_id': songId});
      return true;
    } catch (e) {
      debugPrint('Error removing track from playlist: $e');
      return false;
    }
  }

  static Future<bool> saveReorderedTracks({
    required String playlistId,
    required List<Song> reorderedSongs,
  }) async {
    if (!_isReady) return true;

    try {
      // Delete existing tracks and insert in ordered position batch
      await _client.from('playlist_tracks').delete().eq('playlist_id', playlistId);

      final insertData = reorderedSongs.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        return {
          'playlist_id': playlistId,
          'song_id': s.id,
          'title': s.title,
          'artist': s.artist,
          'cover_url': s.coverUrl,
          'duration_seconds': s.duration.inSeconds,
          'audio_url': s.audioUrl,
          'position': idx,
        };
      }).toList();

      if (insertData.isNotEmpty) {
        await _client.from('playlist_tracks').insert(insertData);
      }
      return true;
    } catch (e) {
      debugPrint('Error reordering playlist tracks: $e');
      return false;
    }
  }

  // ===========================================================================
  // 3. Listening History
  // ===========================================================================

  static Future<List<Map<String, dynamic>>> fetchListeningHistory({int limit = 50}) async {
    if (!_isReady) return [];

    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final List<dynamic> rows = await _client
          .from('listening_history')
          .select()
          .eq('user_id', user.id)
          .order('played_at', ascending: false)
          .limit(limit);

      return rows.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching listening history: $e');
      return [];
    }
  }

  static Future<bool> clearListeningHistory() async {
    if (!_isReady) return true;

    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('listening_history').delete().eq('user_id', user.id);
      return true;
    } catch (e) {
      debugPrint('Error clearing listening history: $e');
      return false;
    }
  }

  // ===========================================================================
  // 4. User Settings
  // ===========================================================================

  static Future<UserSettings?> fetchSettings(String userId) async {
    if (!_isReady) return null;

    try {
      final res = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      return UserSettings.fromMap(res, userId: userId);
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      return null;
    }
  }

  static Future<bool> saveSettings(UserSettings settings) async {
    if (!_isReady) return false;

    try {
      await _client.from('user_settings').upsert(settings.toMap());
      return true;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }
}
