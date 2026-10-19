import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../data/authorized_tracks.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';

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
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note_rounded, size: 64, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('No songs in this playlist yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Tap "Add Songs" above to add your favorite tracks', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
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
                              } else if (val == 'remove' && isOwner) {
                                playlistProv.removeSongFromPlaylist(currentPlaylist.id, song.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'play_next', child: Text('Play Next', style: TextStyle(color: Colors.white))),
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
    // Combine authorized catalog and mock songs
    final allAvailable = <Song>[
      ...AuthorizedMusicCatalog.demoAuthorizedSongs,
      ...MockData.allSongs,
    ];
    final Set<String> seenIds = {};
    final deduplicated = allAvailable.where((s) => seenIds.add(s.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Songs to Playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: deduplicated.length,
                itemBuilder: (c, i) {
                  final s = deduplicated[i];
                  final isAlreadyIn = playlist.songs.any((x) => x.id == s.id);

                  return ListTile(
                    leading: AppNetworkImage(
                      url: s.coverUrl,
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    title: Text(s.title, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(s.artist, maxLines: 1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: isAlreadyIn
                        ? const Icon(Icons.check_circle, color: AppColors.success)
                        : IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: () {
                              playlistProv.addSongToPlaylist(playlist.id, s);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primaryDark,
                                  content: Text('Added "${s.title}" to playlist!'),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
