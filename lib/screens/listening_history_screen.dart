import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/supabase_user_service.dart';
import '../models/song.dart';
import '../data/mock_data.dart';
import '../data/music_onboarding_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import 'artist_profile_screen.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final items = await SupabaseUserService.fetchListeningHistory(limit: 100);
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
          'Are you sure you want to clear your listening history? This will reset your playback history and stats.',
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
    final found = MockData.allSongs.firstWhere(
      (s) => s.id == songId,
      orElse: () => Song(
        id: songId,
        title: item['title']?.toString() ?? 'Unknown Track',
        artist: item['artist']?.toString() ?? 'Unknown Artist',
        album: 'Soundifly',
        coverUrl: item['cover_url']?.toString() ?? '',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: Duration(seconds: (item['duration_seconds'] as num?)?.toInt() ?? 180),
      ),
    );
    return found;
  }

  // --- Statistics computations ---
  int get _totalMinutesListened {
    int totalSec = 0;
    for (final item in _historyItems) {
      totalSec += (item['duration_seconds'] as num?)?.toInt() ?? 180;
    }
    return (totalSec / 60).round();
  }

  List<MapEntry<String, int>> get _topArtists {
    final Map<String, int> counts = {};
    for (final item in _historyItems) {
      final a = (item['artist'] as String?)?.trim();
      if (a != null && a.isNotEmpty) {
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<MapEntry<String, int>> get _topSongs {
    final Map<String, int> counts = {};
    for (final item in _historyItems) {
      final t = (item['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final settingsProv = context.watch<UserSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Listening & Stats', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Recap & Stats'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(player, playlistProv),
                _buildStatsTab(settingsProv),
              ],
            ),
    );
  }

  Widget _buildHistoryList(AudioPlayerProvider player, PlaylistProvider playlistProv) {
    if (_historyItems.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
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
    );
  }

  Widget _buildStatsTab(UserSettingsProvider settingsProv) {
    if (_historyItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No stats available yet',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Listen to more songs to unlock your top artists and monthly recap.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Total Listening Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF6B2200), Color(0xFF281005)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL TIME STREAMED',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_totalMinutesListened mins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${_historyItems.length} playback sessions logged',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const Icon(Icons.equalizer_rounded, color: AppColors.primary, size: 48),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section: Top Artists
        const Text(
          'Your Most Played Artists',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ..._topArtists.map((entry) {
          final artistName = entry.key;
          final count = entry.value;

          OnboardingArtist? matched;
          for (final a in MusicOnboardingData.curatedArtists) {
            if (a.name.toLowerCase() == artistName.toLowerCase()) {
              matched = a;
              break;
            }
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: ClipOval(
                child: AppNetworkImage(
                  url: matched?.imageUrl ?? '',
                  width: 44,
                  height: 44,
                  placeholderIcon: Icons.person_rounded,
                ),
              ),
              title: Text(
                artistName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                '$count plays • ${matched?.artistTypeDisplay ?? "Artist"}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistProfileScreen(
                      artistName: artistName,
                      initialImageUrl: matched?.imageUrl,
                    ),
                  ),
                );
              },
            ),
          );
        }),

        const SizedBox(height: 24),

        // Section: Top Songs
        const Text(
          'Your Top Songs',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ..._topSongs.asMap().entries.map((item) {
          final idx = item.key;
          final entry = item.value;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: SizedBox(
                width: 24,
                child: Text(
                  '#${idx + 1}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              title: Text(
                entry.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                '${entry.value} ${entry.value == 1 ? "stream" : "streams"} logged',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          );
        }),

        const SizedBox(height: 32),
      ],
    );
  }
}
