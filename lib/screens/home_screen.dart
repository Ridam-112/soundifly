import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/listening_room_provider.dart';
import '../services/yt_music_service.dart';
import '../models/song.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import 'playlist_detail_screen.dart';
import 'liked_songs_screen.dart';
import 'listening_history_screen.dart';
import '../widgets/app_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _trendingSongs = [];
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    final songs = await YTMusicService.getTrending();
    if (mounted) {
      setState(() {
        _trendingSongs = songs;
        _isLoadingTrending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final roomProv = context.watch<ListeningRoomProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // App Bar with Greeting & Quick Actions
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.bgDark.withValues(alpha: 0.85),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Soundifly',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                tooltip: 'Listening History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListeningHistoryScreen()),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Greeting & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'What do you want to hear today?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (roomProv.isInRoom)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                roomProv.currentRoom!.isCoupleMode ? 'Couple Sync' : 'In Room',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Hero Featured Card: Glowing Neon Gradient Banner
                  _buildHeroBanner(context, player, roomProv),

                  const SizedBox(height: 24),

                  // Quick Grid (Liked Songs & Recent Playlists)
                  const Text(
                    'Jump Back In',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickAccessGrid(context, playlistProv),

                  const SizedBox(height: 28),

                  // Section: Made for You (Horizontal Cards)
                  _buildSectionHeader('Made For You', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildMadeForYouList(context, player),

                  const SizedBox(height: 28),

                  // Section: Trending Now
                  _buildSectionHeader('Trending Bangladesh & Global', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildTrendingList(context, player, playlistProv),

                  const SizedBox(height: 28),

                  // Section: Moods & Genres
                  _buildSectionHeader('Explore Moods', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildMoodCards(context),

                  // Extra bottom padding for floating mini player
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  Widget _buildHeroBanner(BuildContext context, AudioPlayerProvider player, ListeningRoomProvider roomProv) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B2200), Color(0xFF281005), AppColors.bgSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FEATURED EXPERIENCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('✨ Real-Time Sync', style: TextStyle(color: AppColors.accentAmber, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Listen Together with\nYour Partner or Friends ❤️',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a shared room and sync songs simultaneously anywhere in the world.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
                icon: const Icon(Icons.favorite_rounded, size: 18),
                label: const Text('Couple Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  roomProv.createRoom(name: 'Us & Music ❤️', isCoupleMode: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Couple Room created! Switched to real-time sync.'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Play Mix'),
                onPressed: () {
                  player.playSong(MockData.allSongs.first, playlist: MockData.allSongs);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, PlaylistProvider playlistProv) {
    final playlists = playlistProv.playlists.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, idx) {
        final item = playlists[idx];
        return GestureDetector(
          onTap: () {
            if (item.isLikedFolder) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: item)),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  url: item.coverUrl,
                  width: 54,
                  height: 54,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMadeForYouList(BuildContext context, AudioPlayerProvider player) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: MockData.allSongs.length,
        itemBuilder: (ctx, idx) {
          final song = MockData.allSongs[idx];
          return GestureDetector(
            onTap: () => player.playSong(song, playlist: MockData.allSongs, startIndex: idx),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AppNetworkImage(
                        url: song.coverUrl,
                        width: 140,
                        height: 140,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primaryOrange,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context, AudioPlayerProvider player, PlaylistProvider playlistProv) {
    if (_isLoadingTrending) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final list = _trendingSongs.isNotEmpty ? _trendingSongs : MockData.allSongs;
    final currentSongId = player.currentSong?.id;
    final isPlayingOverall = player.isPlaying;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final song = list[idx];
        final isPlaying = currentSongId == song.id && isPlayingOverall;
        final isLiked = playlistProv.isSongLiked(song.id);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isPlaying ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: isPlaying ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppNetworkImage(
                  url: song.coverUrl,
                  width: 46,
                  height: 46,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isPlaying ? AppColors.primary : Colors.white,
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
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
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: isPlaying ? AppColors.primary : Colors.white70,
                    size: 32,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      player.togglePlayPause();
                    } else {
                      player.playSong(song, playlist: list, startIndex: idx);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodCards(BuildContext context) {
    final moods = [
      {'title': 'Late Night Love ❤️', 'color1': 0xFFFF3366, 'color2': 0xFF990033},
      {'title': 'Bangla Indie Acoustic ☕', 'color1': 0xFFFF6B00, 'color2': 0xFF993D00},
      {'title': 'Chill Lo-Fi Beats 🎧', 'color1': 0xFF6C5CE7, 'color2': 0xFF3D2B85},
      {'title': 'Cyber EDM & Bass 🔥', 'color1': 0xFFFF0055, 'color2': 0xFFFF5500},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moods.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, idx) {
        final m = moods[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [Color(m['color1'] as int), Color(m['color2'] as int)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            m['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
        );
      },
    );
  }
}
