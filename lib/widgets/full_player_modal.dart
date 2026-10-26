import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/listening_room_provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import 'lyrics_viewer.dart';
import 'app_network_image.dart';
import 'song_share_modal.dart';
import 'add_to_playlist_sheet.dart';
import 'embedded_youtube_player.dart';

class FullPlayerModal extends StatefulWidget {
  final int initialTabIndex;
  final VoidCallback? onClose;
  const FullPlayerModal({super.key, this.initialTabIndex = 0, this.onClose});

  @override
  State<FullPlayerModal> createState() => _FullPlayerModalState();
}

class _FullPlayerModalState extends State<FullPlayerModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showVideo = true;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _showVideo = true;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final roomProv = context.watch<ListeningRoomProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final isLiked = playlistProv.isSongLiked(song.id);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null) {
          setState(() {
            _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, 300.0);
          });
        }
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        if (velocity > 200 || _dragOffset > 70) {
          setState(() => _dragOffset = 0.0);
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.of(context).pop();
          }
        } else {
          setState(() => _dragOffset = 0.0);
        }
      },
      onVerticalDragCancel: () {
        setState(() => _dragOffset = 0.0);
      },
      child: AnimatedContainer(
        duration: _dragOffset == 0 ? const Duration(milliseconds: 180) : Duration.zero,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
        ),
        child: Stack(
          children: [
            // Ambient Gradient Glow from top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
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
              child: Column(
                children: [
                  // Modal Drag Handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Top Header (Down button, Playing From info, Together Badge)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.white),
                        onPressed: () {
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      Column(
                        children: [
                          Text(
                            roomProv.isInRoom 
                                ? (roomProv.currentRoom!.isCoupleMode ? 'COUPLE MODE ❤️' : 'LISTENING ROOM 🎧')
                                : 'PLAYING FROM PLAYLIST',
                            style: TextStyle(
                              color: roomProv.isInRoom ? AppColors.primary : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roomProv.isInRoom ? roomProv.currentRoom!.name : song.album,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showVideo ? Icons.image_rounded : Icons.smart_display_rounded,
                              color: _showVideo ? AppColors.primary : Colors.white70,
                              size: 24,
                            ),
                            tooltip: _showVideo ? 'Show Album Cover' : 'Play Video in Box',
                            onPressed: () {
                              if (song.youtubeVideoId.isEmpty) return;
                              setState(() {
                                _showVideo = !_showVideo;
                              });
                              if (_showVideo && player.isPlaying) {
                                player.togglePlayPause();
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              roomProv.isInRoom ? Icons.group : Icons.share_outlined,
                              color: roomProv.isInRoom ? AppColors.primary : Colors.white,
                            ),
                            onPressed: () {
                              if (roomProv.isInRoom) {
                                _showInviteDialog(context, song);
                              } else {
                                SongShareModal.show(
                                  context,
                                  song: song,
                                  lyrics: player.currentLyrics,
                                  activeLyricIndex: player.activeLyricIndex,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs: Now Playing, Lyrics, Queue
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      gradient: AppGradients.primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Player'),
                      Tab(text: 'Lyrics'),
                      Tab(text: 'Up Next'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Content - Preserved with IndexedStack so Player WebView is never destroyed
                Expanded(
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      // TAB 1: Main Artwork & Playback
                      _buildMainPlayerTab(context, song, player, playlistProv, isLiked),

                      // TAB 2: Synced Lyrics View
                      _buildLyricsTab(song, player),

                      // TAB 3: Queue Management Tab
                      _buildQueueTab(context, player),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    ),
  );
}

  Widget _buildMainPlayerTab(
    BuildContext context,
    Song song,
    AudioPlayerProvider player,
    PlaylistProvider playlistProv,
    bool isLiked,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),

          // Big Glowing Album Art or Inline YouTube Video
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.76,
              height: MediaQuery.of(context).size.width * 0.76,
              constraints: const BoxConstraints(maxHeight: 320, maxWidth: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: (_showVideo && song.youtubeVideoId.isNotEmpty)
                  ? EmbeddedYoutubePlayer(
                      videoId: song.youtubeVideoId,
                      width: 320,
                      height: 320,
                      onClose: () => setState(() => _showVideo = false),
                    )
                  : Stack(
                      children: [
                        AppNetworkImage(
                          url: song.coverUrl,
                          width: 320,
                          height: 320,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        if (song.youtubeVideoId.isNotEmpty)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _showVideo = true);
                                if (player.isPlaying) {
                                  player.togglePlayPause();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 16),
                                    SizedBox(width: 5),
                                    Text(
                                      'Watch Video',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          const Spacer(),

          // Title & Artist & Like
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (song.isExplicit) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('E', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.playlist_add_rounded, color: Colors.white70, size: 28),
                tooltip: 'Add to Playlist',
                onPressed: () => AddToPlaylistSheet.show(context, song),
              ),
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.primary : Colors.white70,
                  size: 28,
                ),
                onPressed: () => playlistProv.toggleLikeSong(song),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (player.playbackErrorMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Audio stream restricted.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  if (song.youtubeVideoId.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Play in Box', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        player.clearPlaybackError();
                        setState(() => _showVideo = true);
                      },
                    ),
                ],
              ),
            ),
          ],

          // Seeker Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: player.currentPosition.inSeconds.toDouble().clamp(0.0, player.totalDuration.inSeconds.toDouble()),
              max: player.totalDuration.inSeconds.toDouble() > 0 ? player.totalDuration.inSeconds.toDouble() : 1.0,
              onChanged: (val) {
                player.seekTo(Duration(seconds: val.toInt()));
              },
            ),
          ),

          // Timestamps (Current & Remaining)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(player.currentPosition),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  '-${_formatDuration(player.totalDuration - player.currentPosition)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Controls (Shuffle, Prev, Play/Pause, Next, Loop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: player.isShuffle ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                onPressed: () => player.toggleShuffle(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 38),
                onPressed: () => player.previous(),
              ),
              // Big Neon Glow Play/Pause Circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primaryOrange,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      blurRadius: 22,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: player.isLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                  onPressed: player.isLoading ? null : () => player.togglePlayPause(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 38),
                onPressed: () => player.next(),
              ),
              IconButton(
                icon: Icon(
                  player.loopMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: player.loopMode != LoopMode.off ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                onPressed: () => player.cycleLoopMode(),
              ),
            ],
          ),

          const Spacer(),

          // Bottom Listen Together pill
          GestureDetector(
            onTap: () => _showInviteDialog(context, song),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Listen Together / Couple Mode',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsTab(Song song, AudioPlayerProvider player) {
    return LyricsViewerWidget(
      song: song,
      player: player,
      tabController: _tabController,
    );
  }

  Widget _buildQueueTab(BuildContext context, AudioPlayerProvider player) {
    if (player.queue.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music_rounded, size: 54, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Queue is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Up Next (${player.queue.length} songs)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (player.queue.length > 1)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => player.clearQueue(),
                      child: const Text(
                        'Clear Queue',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Text(
                    'Drag to reorder',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: player.queue.length,
            onReorderItem: (oldIndex, newIndex) => player.reorderQueue(oldIndex, newIndex),
            itemBuilder: (ctx, idx) {
              final item = player.queue[idx];
              final isCurrent = item.id == player.currentSong?.id;

              return Container(
                key: ValueKey(item.id + idx.toString()),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrent ? Border.all(color: AppColors.primary.withValues(alpha: 0.5)) : null,
                ),
                child: ListTile(
                  leading: AppNetworkImage(
                    url: item.coverUrl,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.artist,
                    maxLines: 1,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCurrent)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: () => player.removeFromQueue(idx),
                        ),
                      const Icon(Icons.drag_handle_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                  onTap: () => player.playSong(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context, Song song) {
    final roomProv = Provider.of<ListeningRoomProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.headset_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Start Listening Room', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Listen to this song together in real-time with your partner or friends!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.heartRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite, color: AppColors.heartRed),
              ),
              title: const Text('Couple Mode ❤️', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('Private session with real-time sync & love reactions', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                final room = roomProv.createRoom(name: 'Us & Music ❤️', isCoupleMode: true, initialSong: song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primaryDark,
                    content: Text('Couple Room created! Code: ${room.roomCode}'),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group, color: AppColors.primary),
              ),
              title: const Text('Friends Jam Session', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('Invite friends to play and queue tracks together', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                final room = roomProv.createRoom(name: 'Friends Jam Session', isCoupleMode: false, initialSong: song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primaryDark,
                    content: Text('Jam Room created! Code: ${room.roomCode}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
