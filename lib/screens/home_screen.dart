import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/listening_room_provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/yt_music_service.dart';
import '../services/supabase_user_service.dart';
import '../models/song.dart';
import '../data/mock_data.dart';
import '../data/music_onboarding_data.dart';
import '../theme/app_theme.dart';
import 'playlist_detail_screen.dart';
import 'liked_songs_screen.dart';
import 'listening_history_screen.dart';
import 'library_screen.dart';
import 'artist_profile_screen.dart';
import 'mood_genre_screen.dart';
import 'onboarding/music_onboarding_screen.dart';
import '../widgets/app_network_image.dart';
import '../widgets/add_to_playlist_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _trendingSongs = [];
  bool _isLoadingTrending = true;

  List<Song> _recentlyPlayedSongs = [];
  bool _isLoadingHistory = false;

  final Map<String, List<Song>> _languageHits = {};
  List<Song> _madeForYouSongs = [];
  bool _isLoadingMadeForYou = false;

  String _lastLoadedKey = '';

  @override
  void initState() {
    super.initState();
    _loadTrending();
    _loadRecentlyPlayed();
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

  Future<void> _loadRecentlyPlayed() async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);

    try {
      final items = await SupabaseUserService.fetchListeningHistory(limit: 10);
      if (mounted) {
        setState(() {
          _recentlyPlayedSongs = items.map((item) => _resolveSong(item)).toList();
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Song _resolveSong(Map<String, dynamic> item) {
    final songId = item['song_id']?.toString() ?? '';
    return MockData.allSongs.firstWhere(
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
  }

  Future<void> _loadPersonalizedContent(List<String> languages, List<String> favoriteArtists) async {
    setState(() => _isLoadingMadeForYou = true);

    try {
      if (favoriteArtists.isNotEmpty) {
        final query = favoriteArtists.first;
        final songs = await YTMusicService.search(query);
        if (mounted) {
          setState(() {
            _madeForYouSongs = songs.isNotEmpty ? songs : MockData.allSongs;
            _isLoadingMadeForYou = false;
          });
        }
      } else if (languages.isNotEmpty) {
        final query = '${languages.first} Top Hits';
        final songs = await YTMusicService.search(query);
        if (mounted) {
          setState(() {
            _madeForYouSongs = songs.isNotEmpty ? songs : MockData.allSongs;
            _isLoadingMadeForYou = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _madeForYouSongs = MockData.allSongs;
            _isLoadingMadeForYou = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _madeForYouSongs = MockData.allSongs;
          _isLoadingMadeForYou = false;
        });
      }
    }

    // Load top tracks for up to 3 selected languages
    final langsToFetch = languages.take(3).toList();
    for (final lang in langsToFetch) {
      if (!_languageHits.containsKey(lang)) {
        try {
          final songs = await YTMusicService.search('$lang Hits');
          if (mounted) {
            setState(() {
              _languageHits[lang] = songs.isNotEmpty ? songs : MockData.allSongs;
            });
          }
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final roomProv = context.watch<ListeningRoomProvider>();
    final settingsProv = context.watch<UserSettingsProvider>();

    // Detect preference changes and reactively refresh
    final key = '${settingsProv.preferredLanguages.join(",")}|${settingsProv.favoriteArtists.join(",")}';
    if (_lastLoadedKey != key) {
      _lastLoadedKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadPersonalizedContent(settingsProv.preferredLanguages, settingsProv.favoriteArtists);
          _loadRecentlyPlayed();
        }
      });
    }

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
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
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                tooltip: 'Music Preferences',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MusicOnboardingScreen(isEditingMode: true),
                    ),
                  );
                },
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

                  // Section: Recently Played (if listening history exists)
                  if (_recentlyPlayedSongs.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'Recently Played',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ListeningHistoryScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSongHorizontalCarousel(context, player, _recentlyPlayedSongs),
                  ],

                  // Section: Favourite Artists (from user onboarding preferences)
                  if (settingsProv.favoriteArtists.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'Your Favourite Artists',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MusicOnboardingScreen(isEditingMode: true)),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFavoriteArtistsRow(context, settingsProv.favoriteArtists, player, playlistProv),
                  ],

                  const SizedBox(height: 28),

                  // Section: Made for You (Personalized based on preferences)
                  _buildSectionHeader('Made For You', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildMadeForYouList(context, player),

                  const SizedBox(height: 28),

                  // Section: Daily Mixes & Discover Weekly
                  _buildSectionHeader('Your Daily Mixes & Discover Weekly', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildDailyMixesShelf(context, player, settingsProv),

                  // Section: Language Hits (Bengali Hits, Hindi Hits, English Hits, etc.)
                  for (final lang in settingsProv.preferredLanguages.take(3)) ...[
                    const SizedBox(height: 28),
                    _buildSectionHeader('$lang Hits', onSeeAll: () {}),
                    const SizedBox(height: 12),
                    _buildSongHorizontalCarousel(
                      context,
                      player,
                      _languageHits[lang] ?? MockData.allSongs,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Section: Trending Now (Filtered for user preferences)
                  _buildSectionHeader(
                    settingsProv.preferredLanguages.isNotEmpty
                        ? 'Trending in Your Languages'
                        : 'Trending Bangladesh & Global',
                    onSeeAll: () {},
                  ),
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
                  final mixList = _madeForYouSongs.isNotEmpty ? _madeForYouSongs : MockData.allSongs;
                  if (mixList.isNotEmpty) {
                    player.playSong(mixList.first, playlist: mixList);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, PlaylistProvider playlistProv) {
    final userPlaylists = playlistProv.playlists.take(4).toList();
    final itemCount = userPlaylists.length < 2 ? 2 : userPlaylists.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, idx) {
        if (idx < userPlaylists.length) {
          final item = userPlaylists[idx];
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
        } else {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Create Playlist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          );
        }
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

  Widget _buildFavoriteArtistsRow(
    BuildContext context,
    List<String> favoriteArtists,
    AudioPlayerProvider player,
    PlaylistProvider playlistProv,
  ) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: favoriteArtists.length,
        itemBuilder: (ctx, idx) {
          final artistName = favoriteArtists[idx];
          // Look up matching artist from verified onboarding catalogue
          final match = MusicOnboardingData.artists.firstWhere(
            (a) => a.name.toLowerCase() == artistName.toLowerCase(),
            orElse: () => OnboardingArtist(
              id: 'art_$idx',
              name: artistName,
              languages: const ['Universal'],
              genre: 'Music',
              imageUrl: '',
            ),
          );

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistProfileScreen(
                    artistName: match.name,
                    initialImageUrl: match.imageUrl,
                  ),
                ),
              );
            },
            child: Container(
              width: 88,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: AppNetworkImage(
                        url: match.imageUrl,
                        width: 72,
                        height: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    match.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  void _showArtistTracksModal(
    BuildContext context,
    String artistName,
    AudioPlayerProvider player,
    PlaylistProvider playlistProv,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (sheetCtx, scrollCtrl) {
            return FutureBuilder<List<Song>>(
              future: YTMusicService.search(artistName),
              builder: (context, snapshot) {
                final songs = snapshot.data ?? MockData.allSongs.where((s) => s.artist.toLowerCase().contains(artistName.toLowerCase())).toList();
                final displaySongs = songs.isNotEmpty ? songs : MockData.allSongs;

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ARTIST SPOTLIGHT', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                const SizedBox(height: 2),
                                Text(
                                  artistName,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text('Play All'),
                            onPressed: () {
                              if (displaySongs.isNotEmpty) {
                                player.playSong(displaySongs.first, playlist: displaySongs);
                                Navigator.pop(ctx);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: displaySongs.length,
                          itemBuilder: (context, idx) {
                            final song = displaySongs[idx];
                            final isPlaying = player.currentSong?.id == song.id && player.isPlaying;
                            return ListTile(
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
                                style: TextStyle(
                                  color: isPlaying ? AppColors.primary : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${song.artist} • ${song.formattedDuration}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                  color: isPlaying ? AppColors.primary : Colors.white70,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (isPlaying) {
                                    player.togglePlayPause();
                                  } else {
                                    player.playSong(song, playlist: displaySongs, startIndex: idx);
                                  }
                                },
                              ),
                              onTap: () {
                                player.playSong(song, playlist: displaySongs, startIndex: idx);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMadeForYouList(BuildContext context, AudioPlayerProvider player) {
    if (_isLoadingMadeForYou) {
      return const SizedBox(
        height: 210,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final songs = _madeForYouSongs.isNotEmpty ? _madeForYouSongs : MockData.allSongs;
    return _buildSongHorizontalCarousel(context, player, songs);
  }

  Widget _buildDailyMixesShelf(
    BuildContext context,
    AudioPlayerProvider player,
    UserSettingsProvider settingsProv,
  ) {
    final favoriteArtists = settingsProv.favoriteArtists;
    final preferredLanguages = settingsProv.preferredLanguages;
    final preferredGenres = settingsProv.preferredGenres;

    final artist1 = favoriteArtists.isNotEmpty ? favoriteArtists.first : 'Arijit Singh';
    final artist2 = favoriteArtists.length > 1 ? favoriteArtists[1] : 'Shreya Ghoshal';
    final lang1 = preferredLanguages.isNotEmpty ? preferredLanguages.first : 'Bengali';
    final genre1 = preferredGenres.isNotEmpty ? preferredGenres.first : 'Romantic';

    final mixes = [
      {
        'title': 'Daily Mix 1',
        'subtitle': '$artist1, $artist2 & more',
        'query': '$artist1 $artist2 hits',
        'tag': 'ARTIST MIX',
        'color1': 0xFF1DB954,
        'color2': 0xFF121212,
        'icon': Icons.person_rounded,
      },
      {
        'title': 'Daily Mix 2',
        'subtitle': '$lang1 Top Melodies & Hits',
        'query': '$lang1 top hit songs',
        'tag': 'REGIONAL MIX',
        'color1': 0xFFFF5722,
        'color2': 0xFF212121,
        'icon': Icons.language_rounded,
      },
      {
        'title': 'Daily Mix 3',
        'subtitle': '$genre1 Vibes & Anthems',
        'query': '$genre1 songs',
        'tag': 'MOOD MIX',
        'color1': 0xFF9C27B0,
        'color2': 0xFF1A1A2E,
        'icon': Icons.queue_music_rounded,
      },
      {
        'title': 'Discover Weekly',
        'subtitle': 'Fresh personalized discoveries',
        'query': 'new fresh music hits 2026',
        'tag': 'WEEKLY MIXTAPE',
        'color1': 0xFF00B0FF,
        'color2': 0xFF0A192F,
        'icon': Icons.auto_awesome_rounded,
      },
    ];

    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mixes.length,
        itemBuilder: (ctx, idx) {
          final m = mixes[idx];
          return GestureDetector(
            onTap: () => _showArtistTracksModal(context, m['query'] as String, player, context.read<PlaylistProvider>()),
            child: Container(
              width: 155,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Color(m['color1'] as int), Color(m['color2'] as int)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(m['color1'] as int).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m['tag'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Icon(m['icon'] as IconData, color: Colors.white70, size: 20),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['subtitle'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 26),
                          SizedBox(width: 4),
                          Text(
                            'Play Mix',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongHorizontalCarousel(
    BuildContext context,
    AudioPlayerProvider player,
    List<Song> songs,
  ) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (ctx, idx) {
          final song = songs[idx];
          return GestureDetector(
            onTap: () => player.playSong(song, playlist: songs, startIndex: idx),
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
                  icon: const Icon(Icons.playlist_add_rounded, color: AppColors.textSecondary, size: 22),
                  tooltip: 'Add to Playlist',
                  onPressed: () => AddToPlaylistSheet.show(context, song),
                ),
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
    final genres = MusicOnboardingData.availableGenres.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: genres.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, idx) {
        final g = genres[idx];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MoodGenreScreen(genreMood: g),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: g.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: g.gradient.first.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(g.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        g.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
