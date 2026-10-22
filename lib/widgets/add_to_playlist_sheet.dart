import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final Song song;

  const AddToPlaylistSheet({super.key, required this.song});

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddToPlaylistSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProv = context.watch<PlaylistProvider>();
    final userPlaylists = playlistProv.myPlaylists;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppNetworkImage(
                  url: song.coverUrl,
                  width: 48,
                  height: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add to Playlist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${song.title} • ${song.artist}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white10, height: 24),

          // Action: Create New Playlist
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
            ),
            title: const Text(
              'New Playlist',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Create a new playlist and add this song',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            onTap: () => _showQuickCreateDialog(context, playlistProv),
          ),

          const SizedBox(height: 8),

          // Playlists List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: userPlaylists.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No custom playlists yet.\nTap "New Playlist" above to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: userPlaylists.length,
                    itemBuilder: (ctx, idx) {
                      final playlist = userPlaylists[idx];
                      final isAlreadyAdded = playlist.songs.any((s) => s.id == song.id);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isAlreadyAdded ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: isAlreadyAdded
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppNetworkImage(
                              url: playlist.coverUrl,
                              width: 40,
                              height: 40,
                            ),
                          ),
                          title: Text(
                            playlist.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${playlist.songs.length} songs ${playlist.isCollaborative ? '• Collaborative 👥' : ''}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          trailing: Icon(
                            isAlreadyAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            color: isAlreadyAdded ? AppColors.primary : Colors.white60,
                            size: 24,
                          ),
                          onTap: () {
                            if (isAlreadyAdded) {
                              playlistProv.removeSongFromPlaylist(playlist.id, song.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.bgCard,
                                  content: Text('Removed "${song.title}" from "${playlist.title}"'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              playlistProv.addSongToPlaylist(playlist.id, song);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primary,
                                  content: Text('Added "${song.title}" to "${playlist.title}"!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showQuickCreateDialog(BuildContext context, PlaylistProvider playlistProv) {
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Create New Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final name = titleCtrl.text.trim();
              if (name.isNotEmpty) {
                final newPlaylist = playlistProv.createPlaylist(
                  title: name,
                  description: '',
                  visibility: PlaylistVisibility.public,
                  initialSongs: [song],
                );
                Navigator.pop(ctx);
                Navigator.pop(context); // close sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text('Created "${newPlaylist.title}" with "${song.title}"!'),
                  ),
                );
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }
}
