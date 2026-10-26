import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'full_player_modal.dart';
import 'app_network_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final song = player.currentSong;

    if (song == null) return const SizedBox.shrink();

    final isLiked = playlistProv.isSongLiked(song.id);

    return GestureDetector(
      onTap: () {
        player.openFullPlayer();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // Album Cover Thumbnail with Glow
                      Hero(
                        tag: 'cover_${song.id}',
                        child: AppNetworkImage(
                          url: song.coverUrl,
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Song Title & Artist OR Live Lyrics
                      Expanded(
                        child: player.miniPlayerLyricsMode
                            ? AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  (player.activeLyricLine?.text.isNotEmpty ?? false)
                                      ? player.activeLyricLine!.text
                                      : (player.isLoadingLyrics
                                          ? 'Loading live lyrics...'
                                          : '♪ ${song.title} ♪'),
                                  key: ValueKey(player.activeLyricLine?.text ?? 'default'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    height: 1.25,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
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

                      // Lyrics Mode Toggle Button
                      IconButton(
                        icon: Icon(
                          player.miniPlayerLyricsMode ? Icons.subtitles_rounded : Icons.subtitles_outlined,
                          color: player.miniPlayerLyricsMode ? AppColors.primary : AppColors.textSecondary,
                          size: 20,
                        ),
                        tooltip: player.miniPlayerLyricsMode ? 'Show Song Info' : 'Show Live Lyrics',
                        onPressed: () => player.toggleMiniPlayerLyricsMode(),
                      ),

                      // Like Button
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: () => playlistProv.toggleLikeSong(song),
                      ),

                      // Play / Pause Button with Orange Glow
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.primaryOrange,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
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
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),

              // Bottom Micro Progress Bar
              LinearProgressIndicator(
                value: player.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
