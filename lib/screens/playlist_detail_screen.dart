import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/yt_music_service.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/add_to_playlist_sheet.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isReorderMode = false;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();

    // Grab updated playlist instance from provider if available
    final currentPlaylist = playlistProv.playlists.firstWhere(
      (p) => p.id == widget.playlist.id,
      orElse: () => widget.playlist,
    );

    final isOwner = playlistProv.isOwner(currentPlaylist);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // Collapsible Header with Artwork & Neon Glow
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                tooltip: 'Share playlist',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Playlist link copied! https://soundifly.app/playlist/${currentPlaylist.id}'),
                    ),
                  );
                },
              ),
              if (isOwner && !currentPlaylist.isLikedFolder)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  color: AppColors.bgCard,
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditPlaylistDialog(context, playlistProv, currentPlaylist);
                    } else if (val == 'add') {
                      _showAddSongDialog(context, playlistProv, currentPlaylist);
                    } else if (val == 'reorder') {
                      setState(() => _isReorderMode = !_isReorderMode);
                    } else if (val == 'delete') {
                      _confirmDeletePlaylist(context, playlistProv, currentPlaylist);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit_rounded, size: 18, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Edit Playlist', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: const [
                          Icon(Icons.add_rounded, size: 18, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Add Songs', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reorder',
                      child: Row(
                        children: [
                          Icon(Icons.swap_vert_rounded, size: 18, color: _isReorderMode ? AppColors.primary : Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            _isReorderMode ? 'Done Reordering' : 'Reorder Songs',
                            style: TextStyle(color: _isReorderMode ? AppColors.primary : Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete Playlist', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: currentPlaylist.coverUrl,
                    fit: BoxFit.cover,
                  ),
                  // Dark Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.bgDark.withValues(alpha: 0.8),
                          AppColors.bgDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Visibility Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: currentPlaylist.visibility == PlaylistVisibility.collaborative
                                    ? AppColors.heartRed
                                    : (currentPlaylist.isPublic
                                        ? AppColors.primary
                                        : Colors.white24),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentPlaylist.visibility == PlaylistVisibility.collaborative
                                    ? 'COLLABORATIVE 👥'
                                    : (currentPlaylist.isPublic ? 'PUBLIC 🌐' : 'PRIVATE 🔒'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'By ${currentPlaylist.ownerName}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentPlaylist.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        if (currentPlaylist.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentPlaylist.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '${currentPlaylist.songs.length} songs • ${currentPlaylist.formattedTotalDuration}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons: Play All & Shuffle & Add Songs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Play All Glowing Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primaryOrange,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      onPressed: () {
                        if (currentPlaylist.songs.isNotEmpty) {
                          player.playSong(currentPlaylist.songs.first, playlist: currentPlaylist.songs);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: player.isShuffle ? AppColors.primary : Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      if (currentPlaylist.songs.isNotEmpty) {
                        player.toggleShuffle();
                        player.playSong(currentPlaylist.songs.first, playlist: currentPlaylist.songs);
                      }
                    },
                  ),
                  const Spacer(),
                  if (isOwner)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Songs'),
                      onPressed: () => _showAddSongDialog(context, playlistProv, currentPlaylist),
                    ),
                ],
              ),
            ),
          ),

          // Reorder hint indicator
          if (_isReorderMode)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Drag handle to reorder playlist tracks', style: TextStyle(color: Colors.white, fontSize: 12)),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      onPressed: () => setState(() => _isReorderMode = false),
                      child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // Song List or Empty State
          if (currentPlaylist.songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note_rounded, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No songs in this playlist yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Search and add tracks based on your taste',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add Songs', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddSongDialog(context, playlistProv, currentPlaylist),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_isReorderMode && isOwner)
            SliverToBoxAdapter(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: currentPlaylist.songs.length,
                onReorderItem: (oldIdx, newIdx) => playlistProv.reorderPlaylistSongs(currentPlaylist.id, oldIdx, newIdx),
                itemBuilder: (ctx, idx) {
                  final song = currentPlaylist.songs[idx];
                  return Container(
                    key: ValueKey(song.id + idx.toString()),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: AppNetworkImage(url: song.coverUrl, width: 40, height: 40, borderRadius: BorderRadius.circular(6)),
                      title: Text(song.title, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(song.artist, maxLines: 1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      trailing: const Icon(Icons.drag_handle_rounded, color: AppColors.primary),
                    ),
                  );
                },
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) {
                  final song = currentPlaylist.songs[index];
                  final isCurrent = player.currentSong?.id == song.id;
                  final isLiked = playlistProv.isSongLiked(song.id);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppNetworkImage(
                            url: song.coverUrl,
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? AppColors.primary : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${song.artist} • ${song.formattedDuration}',
                        maxLines: 1,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? AppColors.primary : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => playlistProv.toggleLikeSong(song),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                            color: AppColors.bgCard,
                            onSelected: (val) {
                              if (val == 'play_next') {
                                player.playNext(song);
                              } else if (val == 'add_to_playlist') {
                                AddToPlaylistSheet.show(context, song);
                              } else if (val == 'remove' && isOwner) {
                                playlistProv.removeSongFromPlaylist(currentPlaylist.id, song.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'play_next', child: Text('Play Next', style: TextStyle(color: Colors.white))),
                              const PopupMenuItem(value: 'add_to_playlist', child: Text('Add to another Playlist', style: TextStyle(color: Colors.white))),
                              if (isOwner)
                                const PopupMenuItem(value: 'remove', child: Text('Remove from Playlist', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        player.playSong(song, playlist: currentPlaylist.songs, startIndex: index);
                      },
                    ),
                  );
                },
                childCount: currentPlaylist.songs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _confirmDeletePlaylist(BuildContext context, PlaylistProvider playlistProv, Playlist playlist) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${playlist.title}"? The tracks in this playlist will not be deleted from the catalog.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await playlistProv.deletePlaylist(playlist.id);
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primaryDark,
            content: Text('Playlist deleted successfully.'),
          ),
        );
      }
    }
  }

  void _showEditPlaylistDialog(BuildContext context, PlaylistProvider playlistProv, Playlist playlist) {
    final titleCtrl = TextEditingController(text: playlist.title);
    final descCtrl = TextEditingController(text: playlist.description);
    PlaylistVisibility visibility = playlist.visibility;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Playlist Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Playlist Name',
                    labelStyle: const TextStyle(color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Visibility:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => visibility = PlaylistVisibility.public),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: visibility == PlaylistVisibility.public ? AppColors.primary.withValues(alpha: 0.2) : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: visibility == PlaylistVisibility.public ? AppColors.primary : Colors.white12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Public 🌐',
                            style: TextStyle(
                              color: visibility == PlaylistVisibility.public ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => visibility = PlaylistVisibility.private),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: visibility == PlaylistVisibility.private ? AppColors.primary.withValues(alpha: 0.2) : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: visibility == PlaylistVisibility.private ? AppColors.primary : Colors.white12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Private 🔒',
                            style: TextStyle(
                              color: visibility == PlaylistVisibility.private ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      playlistProv.updatePlaylistDetails(
                        playlistId: playlist.id,
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        visibility: visibility,
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddSongDialog(BuildContext context, PlaylistProvider playlistProv, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddSongsBottomSheet(
        playlist: playlist,
        playlistProv: playlistProv,
      ),
    );
  }
}

class _AddSongsBottomSheet extends StatefulWidget {
  final Playlist playlist;
  final PlaylistProvider playlistProv;

  const _AddSongsBottomSheet({
    required this.playlist,
    required this.playlistProv,
  });

  @override
  State<_AddSongsBottomSheet> createState() => _AddSongsBottomSheetState();
}

class _AddSongsBottomSheetState extends State<_AddSongsBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Song> _results = [];
  bool _isLoading = true;
  String _activeChip = 'Recommended';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialSongs();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSongs() async {
    setState(() => _isLoading = true);
    final settingsProv = context.read<UserSettingsProvider>();

    String initialQuery;
    if (settingsProv.preferredLanguages.isNotEmpty) {
      initialQuery = '${settingsProv.preferredLanguages.first} Top Hits';
    } else if (settingsProv.favoriteArtists.isNotEmpty) {
      initialQuery = settingsProv.favoriteArtists.first;
    } else {
      initialQuery = 'Top Trending Songs';
    }

    try {
      final songs = await YTMusicService.search(initialQuery);
      if (mounted) {
        setState(() {
          _results = songs.isNotEmpty ? songs : MockData.allSongs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = MockData.allSongs;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().isEmpty) {
      _loadInitialSongs();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isLoading = true);
      try {
        final songs = await YTMusicService.search(text.trim());
        if (mounted) {
          setState(() {
            _results = songs;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _onChipSelected(String label) async {
    setState(() {
      _activeChip = label;
      _searchCtrl.clear();
      _isLoading = true;
    });

    final query = label == 'Recommended' ? 'Top Trending Songs' : '$label Hits';
    try {
      final songs = await YTMusicService.search(query);
      if (mounted) {
        setState(() {
          _results = songs.isNotEmpty ? songs : MockData.allSongs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = MockData.allSongs;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<UserSettingsProvider>();
    final chips = <String>[
      'Recommended',
      ...settingsProv.preferredLanguages,
      ...settingsProv.favoriteArtists,
    ];

    // Grab updated playlist to reflect real-time song additions
    final currentPlaylist = widget.playlistProv.playlists.firstWhere(
      (p) => p.id == widget.playlist.id,
      orElse: () => widget.playlist,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetCtx, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Songs to Playlist',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Input Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    hintText: 'Search any song, artist, or album...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadInitialSongs();
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Horizontal Filter Chips
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: chips.length,
                  itemBuilder: (ctx, idx) {
                    final chipLabel = chips[idx];
                    final isSelected = _activeChip == chipLabel && _searchCtrl.text.isEmpty;

                    return GestureDetector(
                      onTap: () => _onChipSelected(chipLabel),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.white12,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          chipLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Colors.white10, height: 20),

              // Results List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 10),
                                Text(
                                  'No songs found matching "${_searchCtrl.text}"',
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _results.length,
                            itemBuilder: (ctx, idx) {
                              final song = _results[idx];
                              final isAdded = currentPlaylist.songs.any((s) => s.id == song.id);

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAdded
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isAdded
                                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
                                      : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AppNetworkImage(
                                      url: song.coverUrl,
                                      width: 44,
                                      height: 44,
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${song.artist} • ${song.formattedDuration}',
                                    maxLines: 1,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  trailing: isAdded
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: AppColors.success),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_rounded, color: AppColors.success, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'Added',
                                                style: TextStyle(
                                                  color: AppColors.success,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          icon: const Icon(Icons.add_rounded, size: 16),
                                          label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            widget.playlistProv.addSongToPlaylist(widget.playlist.id, song);
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: AppColors.primaryDark,
                                                content: Text('Added "${song.title}"!'),
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
