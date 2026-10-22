import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../providers/audio_player_provider.dart';
import '../services/yt_music_service.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

class AlbumDetailModal extends StatefulWidget {
  final Album album;

  const AlbumDetailModal({super.key, required this.album});

  static Future<void> show(BuildContext context, Album album) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AlbumDetailModal(album: album),
    );
  }

  @override
  State<AlbumDetailModal> createState() => _AlbumDetailModalState();
}

class _AlbumDetailModalState extends State<AlbumDetailModal> {
  late Album _album;
  bool _isLoadingTracks = false;

  @override
  void initState() {
    super.initState();
    _album = widget.album;
    if (_album.tracks.isEmpty) {
      _loadTracks();
    }
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoadingTracks = true;
    });

    try {
      final detailed = await YTMusicService.getAlbumDetails(_album.id);
      if (mounted && detailed != null && detailed.tracks.isNotEmpty) {
        setState(() {
          _album = _album.copyWith(tracks: detailed.tracks);
          _isLoadingTracks = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback: search songs for this album title & artist
    try {
      final songs = await YTMusicService.search('${_album.title} ${_album.artist}');
      if (mounted && songs.isNotEmpty) {
        setState(() {
          _album = _album.copyWith(tracks: songs);
          _isLoadingTracks = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingTracks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Modal Handle & Close
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Album Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AppNetworkImage(
                            url: _album.coverUrl,
                            width: 140,
                            height: 140,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _album.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _album.artist,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_album.releaseYear} • ${_album.genre} • ${_album.tracks.length} tracks (${_album.formattedTotalDuration})',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text('Play Album', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              onPressed: () {
                                if (_album.tracks.isNotEmpty) {
                                  player.playSong(_album.tracks.first, playlist: _album.tracks);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tracklist Header
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tracklist',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Tracklist Body
                if (_isLoadingTracks)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  )
                else if (_album.tracks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No tracks found for this album.', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) {
                        final song = _album.tracks[idx];
                        final isPlayingThis = player.currentSong?.id == song.id;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPlayingThis ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgSurface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPlayingThis ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: isPlayingThis ? AppColors.primary : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPlayingThis ? AppColors.primary : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(song.formattedDuration, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                const SizedBox(width: 8),
                                Icon(
                                  isPlayingThis && player.isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                  color: isPlayingThis ? AppColors.primary : Colors.white70,
                                  size: 26,
                                ),
                              ],
                            ),
                            onTap: () {
                              if (isPlayingThis) {
                                player.togglePlayPause();
                              } else {
                                player.playSong(song, playlist: _album.tracks, startIndex: idx);
                              }
                            },
                          ),
                        );
                      },
                      childCount: _album.tracks.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
