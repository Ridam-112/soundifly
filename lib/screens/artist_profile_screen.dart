import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/yt_music_service.dart';
import '../data/music_onboarding_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/add_to_playlist_sheet.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistName;
  final String? initialImageUrl;

  const ArtistProfileScreen({
    super.key,
    required this.artistName,
    this.initialImageUrl,
  });

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  List<Song> _popularSongs = [];
  bool _isLoadingSongs = true;

  OnboardingArtist? _curatedArtist;

  @override
  void initState() {
    super.initState();
    _resolveArtistData();
    _loadTopSongs();
  }

  void _resolveArtistData() {
    final lower = widget.artistName.trim().toLowerCase();
    for (final artist in MusicOnboardingData.curatedArtists) {
      if (artist.name.toLowerCase() == lower) {
        _curatedArtist = artist;
        break;
      }
    }
  }

  Future<void> _loadTopSongs() async {
    setState(() {
      _isLoadingSongs = true;
    });

    try {
      final results = await YTMusicService.getArtistSongs(widget.artistName);
      if (mounted) {
        final targetLower = widget.artistName.trim().toLowerCase();
        // Strict filter: ensure tracks on this profile belong to this artist
        final filtered = results.where((s) {
          final a = s.artist.toLowerCase();
          return a.contains(targetLower) || targetLower.contains(a);
        }).toList();

        setState(() {
          _popularSongs = filtered.isNotEmpty ? filtered : results;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _popularSongs = [];
          _isLoadingSongs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final settingsProv = context.watch<UserSettingsProvider>();

    final isFollowed = settingsProv.isArtistFollowed(widget.artistName);
    final imageUrl = widget.initialImageUrl ?? _curatedArtist?.imageUrl ?? '';
    final languages = _curatedArtist?.languages ?? ['Universal'];
    final artistType = _curatedArtist?.artistTypeDisplay ?? 'Verified Artist';

    // Discovered similar artists from same language/genre
    final similarArtists = MusicOnboardingData.curatedArtists.where((a) {
      if (a.name.toLowerCase() == widget.artistName.toLowerCase()) return false;
      return a.languages.any((l) => languages.contains(l));
    }).take(6).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // 1. Collapsible Hero Banner with Verified Portrait
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                tooltip: 'Share Artist',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Sharing ${widget.artistName} profile'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    AppNetworkImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.person_rounded,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.6),
                            AppColors.bgDark,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.artistName.isNotEmpty ? widget.artistName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  // Dark gradient overlay for readable text
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.bgDark.withValues(alpha: 0.5),
                          AppColors.bgDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.4, 0.75, 1.0],
                      ),
                    ),
                  ),
                  // Artist Name & Badge on bottom of banner
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              artistType,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.artistName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Action Bar (Follow, Play All, Shuffle)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Follow / Following Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFollowed ? Colors.white : AppColors.primary,
                      backgroundColor: isFollowed ? AppColors.bgSurface : Colors.transparent,
                      side: BorderSide(
                        color: isFollowed ? Colors.white24 : AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: Icon(
                      isFollowed ? Icons.check_rounded : Icons.favorite_border_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isFollowed ? 'Following' : 'Follow',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () => settingsProv.toggleFollowArtist(widget.artistName),
                  ),
                  const Spacer(),
                  // Shuffle Button
                  IconButton(
                    icon: Icon(
                      player.isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                      color: player.isShuffle ? AppColors.primary : Colors.white70,
                      size: 26,
                    ),
                    tooltip: 'Shuffle',
                    onPressed: () {
                      player.toggleShuffle();
                      if (_popularSongs.isNotEmpty && !player.isPlaying) {
                        player.playSong(_popularSongs.first, playlist: _popularSongs);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Master Play Floating Circle
                  GestureDetector(
                    onTap: () {
                      if (_popularSongs.isEmpty) return;
                      final isCurrentArtistPlaying = player.isPlaying &&
                          player.currentSong != null &&
                          player.currentSong!.artist.toLowerCase().contains(widget.artistName.toLowerCase());
                      if (isCurrentArtistPlaying) {
                        player.togglePlayPause();
                      } else {
                        player.playSong(_popularSongs.first, playlist: _popularSongs);
                      }
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primaryOrange,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        (player.isPlaying &&
                                player.currentSong != null &&
                                player.currentSong!.artist.toLowerCase().contains(widget.artistName.toLowerCase()))
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Languages tags
          if (languages.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: languages.map((lang) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        lang,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 4. Section Title: Popular Tracks
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Tracks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_popularSongs.isNotEmpty)
                    Text(
                      '${_popularSongs.length} songs',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),

          // 5. Popular Songs List
          if (_isLoadingSongs)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            )
          else if (_popularSongs.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No songs found for this artist.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _popularSongs[index];
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
                        song.formattedDuration,
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
                                player.playSong(song, playlist: _popularSongs, startIndex: index);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _popularSongs.length,
              ),
            ),

          // 6. Section Title: Fans Also Like
          if (similarArtists.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Fans Also Like',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 145,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: similarArtists.length,
                  itemBuilder: (context, index) {
                    final artist = similarArtists[index];
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
                        width: 96,
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white12, width: 1.5),
                              ),
                              child: ClipOval(
                                child: AppNetworkImage(
                                  url: artist.imageUrl,
                                  width: 76,
                                  height: 76,
                                  placeholderIcon: Icons.person_rounded,
                                ),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              artist.artistTypeDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
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

          // Safe padding at bottom for mini player
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
