import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final auth = context.watch<AuthProvider>();

    final songs = playlistProv.sortedLikedSongs;
    final totalDuration = songs.fold(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );

    final durationFormatted = totalDuration.inMinutes > 60
        ? '${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m'
        : '${totalDuration.inMinutes} mins';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // Header with Heart Gradient Banner
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<LikedSongsSort>(
                icon: const Icon(Icons.sort_rounded, color: Colors.white),
                color: AppColors.bgCard,
                tooltip: 'Sort liked songs',
                onSelected: (sort) => playlistProv.setLikedSortOrder(sort),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: LikedSongsSort.recentlyLiked,
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: playlistProv.likedSortOrder == LikedSongsSort.recentlyLiked
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Recently Added',
                          style: TextStyle(
                            color: playlistProv.likedSortOrder == LikedSongsSort.recentlyLiked
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: playlistProv.likedSortOrder == LikedSongsSort.recentlyLiked
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: LikedSongsSort.title,
                    child: Row(
                      children: [
                        Icon(
                          Icons.title_rounded,
                          size: 18,
                          color: playlistProv.likedSortOrder == LikedSongsSort.title
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Title (A-Z)',
                          style: TextStyle(
                            color: playlistProv.likedSortOrder == LikedSongsSort.title
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: playlistProv.likedSortOrder == LikedSongsSort.title
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: LikedSongsSort.artist,
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: playlistProv.likedSortOrder == LikedSongsSort.artist
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Artist',
                          style: TextStyle(
                            color: playlistProv.likedSortOrder == LikedSongsSort.artist
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: playlistProv.likedSortOrder == LikedSongsSort.artist
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF881133),
                      Color(0xFF44091A),
                      AppColors.bgDark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3366), Color(0xFFFF5500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.heartRed.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PLAYLIST',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Liked Songs',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${songs.length} songs • $durationFormatted',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Row: Play All, Shuffle, Queue All
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
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
                          player.playSong(songs.first, playlist: songs);
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
                        player.toggleShuffle();
                        player.playSong(songs.first, playlist: songs);
                      },
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.queue_music_rounded, size: 18),
                      label: const Text('Add to Queue'),
                      onPressed: () {
                        for (final s in songs) {
                          player.addToQueue(s);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primaryDark,
                            content: Text('Added ${songs.length} liked songs to queue!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Logged-out Banner
          if (!auth.isAuthenticated)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.accentAmber, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Sign in to sync your liked songs permanently across all your devices.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Songs List or Empty State
          if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.textMuted),
                    SizedBox(height: 16),
                    Text(
                      'No liked songs yet',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap the heart icon on any track to save it here',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) {
                  final song = songs[index];
                  final isCurrent = player.currentSong?.id == song.id;

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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppNetworkImage(
                              url: song.coverUrl,
                              width: 44,
                              height: 44,
                            ),
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
                            icon: const Icon(Icons.favorite, color: AppColors.heartRed, size: 22),
                            onPressed: () => playlistProv.toggleLikeSong(song),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                            color: AppColors.bgCard,
                            onSelected: (val) {
                              if (val == 'play_next') {
                                player.playNext(song);
                              } else if (val == 'add_queue') {
                                player.addToQueue(song);
                              } else if (val == 'unlike') {
                                playlistProv.toggleLikeSong(song);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'play_next', child: Text('Play Next', style: TextStyle(color: Colors.white))),
                              const PopupMenuItem(value: 'add_queue', child: Text('Add to Queue', style: TextStyle(color: Colors.white))),
                              const PopupMenuItem(value: 'unlike', child: Text('Remove from Liked', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        player.playSong(song, playlist: songs, startIndex: index);
                      },
                    ),
                  );
                },
                childCount: songs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
