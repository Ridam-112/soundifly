import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/supabase_user_service.dart';
import '../models/song.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen> {
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final items = await SupabaseUserService.fetchListeningHistory();
    if (mounted) {
      setState(() {
        _historyItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear Listening History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to clear your listening history? This will only remove your playback history and will not affect your playlists or liked songs.',
          style: TextStyle(color: AppColors.textSecondary),
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
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SupabaseUserService.clearListeningHistory();
      if (mounted) {
        setState(() {
          _historyItems.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success ? AppColors.primaryDark : AppColors.error,
            content: Text(success ? 'Listening history cleared!' : 'Failed to clear history.'),
          ),
        );
      }
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    final dt = DateTime.tryParse(timestamp.toString());
    if (dt == null) return 'Recently';

    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Song _resolveSong(Map<String, dynamic> item) {
    final songId = item['song_id']?.toString() ?? '';
    // Check if song exists in mock or authorized catalog for clean audio playback
    final found = MockData.allSongs.firstWhere(
      (s) => s.id == songId,
      orElse: () => Song(
        id: songId,
        title: item['title']?.toString() ?? 'Unknown Track',
        artist: item['artist']?.toString() ?? 'Unknown Artist',
        album: 'Soundifly',
        coverUrl: item['cover_url']?.toString() ??
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=600&auto=format&fit=crop&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: Duration(seconds: (item['duration_seconds'] as num?)?.toInt() ?? 180),
      ),
    );
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Listening History', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              tooltip: 'Clear history',
              onPressed: _clearHistory,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _historyItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'No listening history yet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tracks you listen to will appear here in reverse chronological order',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Discover Music'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _historyItems.length,
                  itemBuilder: (ctx, idx) {
                    final item = _historyItems[idx];
                    final song = _resolveSong(item);
                    final isCurrent = player.currentSong?.id == song.id;
                    final isLiked = playlistProv.isSongLiked(song.id);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                            url: song.coverUrl,
                            width: 48,
                            height: 48,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? AppColors.primary : Colors.white,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${_formatTimeAgo(item['played_at'])}',
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
                            IconButton(
                              icon: Icon(
                                isCurrent && player.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                color: isCurrent ? AppColors.primary : Colors.white70,
                                size: 30,
                              ),
                              onPressed: () {
                                if (isCurrent) {
                                  player.togglePlayPause();
                                } else {
                                  player.playSong(song);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () => player.playSong(song),
                      ),
                    );
                  },
                ),
    );
  }
}
