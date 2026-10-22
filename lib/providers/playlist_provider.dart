import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../data/mock_data.dart';
import '../services/supabase_service.dart';
import '../services/supabase_music_sync_service.dart';
import '../services/supabase_user_service.dart';

enum LikedSongsSort {
  recentlyLiked,
  title,
  artist,
}

class PlaylistProvider extends ChangeNotifier {
  final List<Playlist> _playlists = [];
  final Set<String> _likedSongIds = {};
  final Map<String, DateTime> _likedTimestamps = {};
  LikedSongsSort _likedSortOrder = LikedSongsSort.recentlyLiked;
  bool _isLoadingPlaylists = false;

  PlaylistProvider() {
    _initDefaultPlaylists();
  }

  List<Playlist> get playlists => _playlists;
  List<Playlist> get publicPlaylists => _playlists.where((p) => p.isPublic).toList();
  List<Playlist> get myPlaylists => _playlists.where((p) {
    if (p.isLikedFolder) return false;
    if (isOwner(p)) return true;
    if (p.isCollaborative) {
      final user = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;
      if (user?.email != null && p.collaboratorEmail != null) {
        return p.collaboratorEmail!.trim().toLowerCase() == user!.email!.trim().toLowerCase();
      }
    }
    return false;
  }).toList();
  bool get isLoadingPlaylists => _isLoadingPlaylists;
  LikedSongsSort get likedSortOrder => _likedSortOrder;

  Playlist get likedSongsPlaylist {
    final idx = _playlists.indexWhere((p) => p.isLikedFolder);
    if (idx != -1) return _playlists[idx];
    return MockData.initialPlaylists.first;
  }

  List<Song> get sortedLikedSongs {
    final list = List<Song>.from(likedSongsPlaylist.songs);
    switch (_likedSortOrder) {
      case LikedSongsSort.recentlyLiked:
        list.sort((a, b) {
          final tA = _likedTimestamps[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = _likedTimestamps[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });
        break;
      case LikedSongsSort.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LikedSongsSort.artist:
        list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
    }
    return list;
  }

  void setLikedSortOrder(LikedSongsSort sort) {
    _likedSortOrder = sort;
    notifyListeners();
  }

  bool isOwner(Playlist playlist) {
    if (playlist.ownerId == 'u_current') return true;
    if (!SupabaseService.isInitialized) return true;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;
    if (playlist.ownerId == user.id) return true;
    // Collaborator access check: allowed to edit / add tracks
    if (playlist.isCollaborative) {
      if (playlist.collaboratorEmail != null && user.email != null) {
        if (playlist.collaboratorEmail!.trim().toLowerCase() == user.email!.trim().toLowerCase()) {
          return true;
        }
      }
    }
    return false;
  }

  void _initDefaultPlaylists() {
    _playlists.clear();
    _playlists.addAll(MockData.initialPlaylists);

    final now = DateTime.now();
    for (int i = 0; i < likedSongsPlaylist.songs.length; i++) {
      final s = likedSongsPlaylist.songs[i];
      _likedSongIds.add(s.id);
      _likedTimestamps[s.id] = now.subtract(Duration(hours: i * 2));
    }

    refreshFromCloud();
  }

  /// Reload playlists and favorites from Supabase when user logs in or starts app
  Future<void> refreshFromCloud() async {
    if (!SupabaseService.isInitialized) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    _isLoadingPlaylists = true;
    notifyListeners();

    try {
      // 1. Fetch cloud favorites
      final cloudFavorites = await SupabaseMusicSyncService.fetchUserFavoriteSongs();
      if (cloudFavorites.isNotEmpty) {
        final likedIndex = _playlists.indexWhere((p) => p.isLikedFolder);
        if (likedIndex != -1) {
          final existingSongs = Map<String, Song>.fromEntries(
            _playlists[likedIndex].songs.map((s) => MapEntry(s.id, s)),
          );

          final List<Song> combinedLiked = [];
          for (final fav in cloudFavorites) {
            _likedSongIds.add(fav.song.id);
            _likedTimestamps[fav.song.id] = fav.likedAt;

            // Prefer rich local metadata if available
            final existing = existingSongs[fav.song.id] ??
                MockData.allSongs.firstWhere((s) => s.id == fav.song.id, orElse: () => fav.song);
            combinedLiked.add(existing);
          }

          _playlists[likedIndex] = _playlists[likedIndex].copyWith(songs: combinedLiked);
        }
      }

      // 2. Fetch user custom playlists
      final cloudPlaylists = await SupabaseUserService.fetchUserPlaylists(user.id);
      if (cloudPlaylists.isNotEmpty) {
        // Keep Liked Songs folder and public featured playlists
        final nonUserPlaylists = _playlists.where((p) => p.isLikedFolder || p.ownerId == 'u_admin' || p.ownerId == 'u_dhaka').toList();
        _playlists.clear();
        _playlists.add(nonUserPlaylists.firstWhere((p) => p.isLikedFolder));
        _playlists.addAll(cloudPlaylists);
        for (final p in nonUserPlaylists) {
          if (!p.isLikedFolder && !_playlists.any((x) => x.id == p.id)) {
            _playlists.add(p);
          }
        }
      }
    } catch (e) {
      debugPrint('Cloud refresh note: $e');
    } finally {
      _isLoadingPlaylists = false;
      notifyListeners();
    }
  }

  bool isSongLiked(String songId) {
    return _likedSongIds.contains(songId);
  }

  void toggleLikeSong(Song song) {
    final likedIndex = _playlists.indexWhere((p) => p.isLikedFolder);
    if (likedIndex == -1) return;

    final bool isNowLiked;
    if (_likedSongIds.contains(song.id)) {
      _likedSongIds.remove(song.id);
      _likedTimestamps.remove(song.id);
      _playlists[likedIndex].songs.removeWhere((s) => s.id == song.id);
      isNowLiked = false;
    } else {
      _likedSongIds.add(song.id);
      _likedTimestamps[song.id] = DateTime.now();
      _playlists[likedIndex].songs.insert(0, song);
      isNowLiked = true;
    }
    notifyListeners();
    SupabaseMusicSyncService.syncFavorite(song, isNowLiked);
  }

  Playlist createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    String? coverUrl,
    List<Song>? initialSongs,
    String? collaboratorEmail,
  }) {
    final currentUserId = SupabaseService.isInitialized
        ? (SupabaseService.client.auth.currentUser?.id ?? 'u_current')
        : 'u_current';

    final tempId = const Uuid().v4();
    final newPlaylist = Playlist(
      id: tempId,
      title: title.trim().isEmpty ? 'My Playlist #${_playlists.length + 1}' : title.trim(),
      description: description.trim(),
      coverUrl: coverUrl ?? 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      ownerName: 'You',
      ownerId: currentUserId,
      visibility: visibility,
      collaboratorEmail: collaboratorEmail?.trim(),
      collaboratorNames: visibility == PlaylistVisibility.collaborative
          ? [collaboratorEmail?.trim() ?? 'Partner', 'You']
          : [],
      songs: initialSongs != null ? List.from(initialSongs) : [],
    );

    // Insert right after Liked Songs folder
    _playlists.insert(1, newPlaylist);
    notifyListeners();

    // Persist to Supabase in background
    if (SupabaseService.isInitialized && SupabaseService.client.auth.currentUser != null) {
      SupabaseUserService.createPlaylist(newPlaylist).then((cloudPlaylist) {
        if (cloudPlaylist != null && cloudPlaylist.id != tempId) {
          final idx = _playlists.indexWhere((p) => p.id == tempId);
          if (idx != -1) {
            _playlists[idx] = cloudPlaylist.copyWith(songs: newPlaylist.songs);
            notifyListeners();
          }
        }
      });
    }

    return newPlaylist;
  }

  Future<void> updatePlaylistDetails({
    required String playlistId,
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    String? coverUrl,
  }) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    final updated = _playlists[idx].copyWith(
      title: title.trim(),
      description: description.trim(),
      visibility: visibility,
      coverUrl: coverUrl,
    );
    _playlists[idx] = updated;
    notifyListeners();

    await SupabaseUserService.updatePlaylist(updated);
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId && !p.isLikedFolder);
    notifyListeners();

    await SupabaseUserService.deletePlaylist(playlistId);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      if (!_playlists[index].songs.any((s) => s.id == song.id)) {
        _playlists[index].songs.add(song);
        final position = _playlists[index].songs.length - 1;
        notifyListeners();

        await SupabaseUserService.addTrackToPlaylist(
          playlistId: playlistId,
          song: song,
          position: position,
        );
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index].songs.removeWhere((s) => s.id == songId);
      notifyListeners();

      await SupabaseUserService.removeTrackFromPlaylist(
        playlistId: playlistId,
        songId: songId,
      );
    }
  }

  Future<void> reorderPlaylistSongs(String playlistId, int oldIndex, int newIndex) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _playlists[index].songs.removeAt(oldIndex);
    _playlists[index].songs.insert(newIndex, item);
    notifyListeners();

    await SupabaseUserService.saveReorderedTracks(
      playlistId: playlistId,
      reorderedSongs: _playlists[index].songs,
    );
  }
}
