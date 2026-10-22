import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/yt_music_service.dart';
import '../data/music_onboarding_data.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/add_to_playlist_sheet.dart';
import 'artist_profile_screen.dart';

class MoodGenreScreen extends StatefulWidget {
  final MusicGenreMood genreMood;

  const MoodGenreScreen({super.key, required this.genreMood});

  @override
  State<MoodGenreScreen> createState() => _MoodGenreScreenState();
}

class _MoodGenreScreenState extends State<MoodGenreScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGenreSongs();
  }

  Future<void> _loadGenreSongs() async {
    setState(() => _isLoading = true);
    try {
      final results = await YTMusicService.search('${widget.genreMood.name} Songs');
      if (mounted) {
        setState(() {
          _songs = results.isNotEmpty ? results : MockData.allSongs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _songs = MockData.allSongs;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();

    // Curated artists associated with this genre
    final matchingArtists = MusicOnboardingData.curatedArtists.where((a) {
      final q = widget.genreMood.id.toLowerCase();
      return a.genre.toLowerCase().contains(q) ||
          a.genre.toLowerCase().contains(widget.genreMood.name.toLowerCase());
    }).take(6).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // 1. Collapsible Gradient Header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ...widget.genreMood.gradient,
                      AppColors.bgDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.genreMood.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 10),
                        Icon(widget.genreMood.icon, color: Colors.white70, size: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.genreMood.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.genreMood.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Play & Shuffle Action Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _songs.isNotEmpty
                        ? () => player.playSong(_songs.first, playlist: _songs)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: Icon(
                      player.isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                      size: 20,
                      color: player.isShuffle ? AppColors.primary : Colors.white70,
                    ),
                    label: const Text('Shuffle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    onPressed: () {
                      player.toggleShuffle();
                      if (_songs.isNotEmpty && !player.isPlaying) {
                        player.playSong(_songs.first, playlist: _songs);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Featured Artists for this Genre (if any)
          if (matchingArtists.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Featured Artists',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: matchingArtists.length,
                  itemBuilder: (context, idx) {
                    final artist = matchingArtists[idx];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistProfileScreen(
                              artistName: artist.name,
                              initialImageUrl: artist.imageUrl,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            ClipOval(
                              child: AppNetworkImage(
                                url: artist.imageUrl,
                                width: 68,
                                height: 68,
                                placeholderIcon: Icons.person_rounded,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // 4. Track List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Curated Tracks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_songs.isNotEmpty)
                    Text(
                      '${_songs.length} tracks',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),

          // 5. Track List
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  final isCurrent = player.currentSong?.id == song.id;
                  final isPlaying = isCurrent && player.isPlaying;
                  final isLiked = playlistProv.isSongLiked(song.id);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                          color: isCurrent ? AppColors.primary : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${song.artist} • ${song.formattedDuration}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isLiked ? AppColors.primary : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => playlistProv.toggleLikeSong(song),
                          ),
                          IconButton(
                            icon: const Icon(Icons.playlist_add_rounded, color: AppColors.textSecondary, size: 22),
                            onPressed: () => AddToPlaylistSheet.show(context, song),
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                              color: isCurrent ? AppColors.primary : Colors.white70,
                              size: 32,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                player.togglePlayPause();
                              } else {
                                player.playSong(song, playlist: _songs, startIndex: index);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _songs.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
