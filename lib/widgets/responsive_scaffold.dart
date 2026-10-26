import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/listening_room_provider.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/library_screen.dart';
import '../screens/together_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_theme.dart';
import 'mini_player.dart';
import 'full_player_modal.dart';
import 'app_network_image.dart';

class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({super.key});

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    TogetherScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(context),
    );
  }

  // Mobile / Tablet Layout (< 900px)
  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        // Floating Mini Player right above Bottom Bar
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MiniPlayer(),
        ),
      ],
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    final roomProv = context.watch<ListeningRoomProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: Colors.white10, width: 0.8)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_music_rounded),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite_rounded),
                if (roomProv.isInRoom)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Together',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Desktop / Web Layout (>= 900px)
  Widget _buildDesktopLayout(BuildContext context) {
    final playlistProv = context.watch<PlaylistProvider>();
    final roomProv = context.watch<ListeningRoomProvider>();

    return Column(
      children: [
        // Top area: Sidebar + Main Content View
        Expanded(
          child: Row(
            children: [
              // Desktop Left Sidebar
              Container(
                width: 250,
                color: AppColors.bgSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Soundifly Brand Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Soundifly',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sidebar Navigation Links
                    _buildSidebarItem(0, Icons.home_rounded, 'Home'),
                    _buildSidebarItem(1, Icons.search_rounded, 'Search'),
                    _buildSidebarItem(2, Icons.library_music_rounded, 'Your Library'),
                    _buildSidebarItem(
                      3,
                      Icons.favorite_rounded,
                      'Listen Together ❤️',
                      badge: roomProv.isInRoom ? 'ACTIVE' : null,
                    ),
                    _buildSidebarItem(4, Icons.person_rounded, 'Profile & Settings'),

                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: Colors.white10),
                    ),
                    const SizedBox(height: 10),

                    // Quick Playlists list
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'PLAYLISTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: playlistProv.playlists.length,
                        itemBuilder: (ctx, idx) {
                          final p = playlistProv.playlists[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            onTap: () {
                              setState(() => _currentIndex = 2);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Body
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),

        // Desktop Persistent Bottom Playback Bar
        const RepaintBoundary(child: DesktopBottomPlayerBar()),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, {String? badge}) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              )
            : null,
        onTap: () => setState(() => _currentIndex = index),
      ),
    );
  }
}

class DesktopBottomPlayerBar extends StatelessWidget {
  const DesktopBottomPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final isLiked = playlistProv.isSongLiked(song.id);

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Left: Current Song Info & Heart
          SizedBox(
            width: 250,
            child: Row(
              children: [
                AppNetworkImage(
                  url: song.coverUrl,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      if (player.playbackErrorMessage != null)
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                player.clearPlaybackError();
                                player.playSong(song);
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, color: AppColors.primary, size: 12),
                                  SizedBox(width: 3),
                                  Text('Retry', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final ytUrl = song.youtubeEmbedUrl.isNotEmpty ? song.youtubeEmbedUrl : song.youtubeWatchUrl;
                                launchUrl(Uri.parse(ytUrl), mode: LaunchMode.inAppWebView);
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new_rounded, color: Colors.amberAccent, size: 12),
                                  SizedBox(width: 3),
                                  Text('YouTube', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? AppColors.primary : AppColors.textSecondary, size: 22),
                  onPressed: () => playlistProv.toggleLikeSong(song),
                ),
              ],
            ),
          ),

          // Center: Playback Controls & Seeker
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle_rounded, color: player.isShuffle ? AppColors.primary : AppColors.textSecondary, size: 20),
                      onPressed: () => player.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                      onPressed: () => player.previous(),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primaryOrange,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10),
                        ],
                      ),
                      child: IconButton(
                        icon: player.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                        onPressed: player.isLoading ? null : () => player.togglePlayPause(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                      onPressed: () => player.next(),
                    ),
                    IconButton(
                      icon: Icon(
                        player.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                        color: player.loopMode != LoopMode.off ? AppColors.primary : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => player.cycleLoopMode(),
                    ),
                  ],
                ),
                SizedBox(
                  height: 22,
                  child: Row(
                    children: [
                      Text(_formatDuration(player.currentPosition), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          ),
                          child: Slider(
                            value: player.currentPosition.inSeconds.toDouble().clamp(0.0, player.totalDuration.inSeconds.toDouble()),
                            max: player.totalDuration.inSeconds.toDouble() > 0 ? player.totalDuration.inSeconds.toDouble() : 1.0,
                            activeColor: AppColors.primary,
                            inactiveColor: Colors.white12,
                            onChanged: (v) => player.seekTo(Duration(seconds: v.toInt())),
                          ),
                        ),
                      ),
                      Text(_formatDuration(player.totalDuration), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Volume Slider & Full Screen Player Button
          SizedBox(
            width: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Lyrics & Queue',
                  icon: const Icon(Icons.queue_music_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const FullPlayerModal(),
                    );
                  },
                ),
                const Icon(Icons.volume_up_rounded, color: AppColors.textSecondary, size: 20),
                SizedBox(
                  width: 90,
                  child: Slider(
                    value: player.volume,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => player.setVolume(v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
