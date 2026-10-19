import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../theme/app_theme.dart';

class LyricsViewerWidget extends StatefulWidget {
  final Song song;
  final AudioPlayerProvider player;
  final TabController? tabController;

  const LyricsViewerWidget({
    super.key,
    required this.song,
    required this.player,
    this.tabController,
  });

  @override
  State<LyricsViewerWidget> createState() => _LyricsViewerWidgetState();
}

class _LyricsViewerWidgetState extends State<LyricsViewerWidget> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  int _lastActiveIndex = -1;
  bool _isUserScrolling = false;
  Timer? _userScrollResumeTimer;
  bool _hasInitialScrolled = false;

  @override
  void initState() {
    super.initState();
    widget.tabController?.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // When user taps/swipes into the Lyrics tab (tab index 1)
    if (widget.tabController?.index == 1) {
      _isUserScrolling = false;
      _userScrollResumeTimer?.cancel();
      _lastActiveIndex = -1; // Force re-centering on the current active line
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCurrentActive(isImmediate: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant LyricsViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController) {
      oldWidget.tabController?.removeListener(_handleTabChange);
      widget.tabController?.addListener(_handleTabChange);
    }
    if (oldWidget.song.id != widget.song.id ||
        oldWidget.song.lyrics.length != widget.song.lyrics.length) {
      _itemKeys.clear();
      _lastActiveIndex = -1;
      _isUserScrolling = false;
      _hasInitialScrolled = false;
      _userScrollResumeTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    widget.tabController?.removeListener(_handleTabChange);
    _userScrollResumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  int _calculateActiveIndex() {
    if (widget.player.activeLyricIndex >= 0) {
      return widget.player.activeLyricIndex;
    }
    final lyrics = widget.player.currentLyrics.lines.isNotEmpty 
        ? widget.player.currentLyrics.lines 
        : widget.song.lyrics;
    if (lyrics.isEmpty) return -1;

    final currentSeconds = widget.player.currentPosition.inSeconds;
    for (int i = 0; i < lyrics.length; i++) {
      if (currentSeconds >= lyrics[i].timestamp.inSeconds) {
        if (i == lyrics.length - 1 || currentSeconds < lyrics[i + 1].timestamp.inSeconds) {
          return i;
        }
      }
    }
    return -1;
  }

  void _scrollToCurrentActive({bool isImmediate = false}) {
    final activeIndex = _calculateActiveIndex();
    if (activeIndex != -1) {
      _scrollToActiveLine(activeIndex, isImmediate: isImmediate);
    }
  }

  void _scrollToActiveLine(int index, {bool isImmediate = false}) {
    if (_isUserScrolling) return;

    // If TabController is attached and we are not currently on the Lyrics tab (tab 1),
    // do not scroll or lock _lastActiveIndex while hidden
    if (widget.tabController != null && widget.tabController!.index != 1) {
      return;
    }

    final key = _itemKeys[index];
    if (key == null || key.currentContext == null) {
      // If layout has not finished attaching the GlobalKey, wait for next frame and retry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isUserScrolling) {
          _scrollToActiveLine(index, isImmediate: isImmediate);
        }
      });
      return;
    }

    if (_lastActiveIndex == index && !isImmediate) return;
    _lastActiveIndex = index;

    // alignment: 0.5 centers the widget precisely in the middle of the viewport
    Scrollable.ensureVisible(
      key.currentContext!,
      alignment: 0.5,
      duration: isImmediate ? const Duration(milliseconds: 250) : const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.player.currentLyrics.lines.isNotEmpty
        ? widget.player.currentLyrics.lines
        : widget.song.lyrics;

    if (widget.player.isLoadingLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Finding synchronized lyrics...',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Searching LRCLIB & cloud database for "${widget.song.title}"',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note_rounded, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No lyrics found for this song',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Enjoy the pure melody of "${widget.song.title}"',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final activeIndex = _calculateActiveIndex();

    // Check if we need to auto-scroll to the active line
    if (activeIndex != -1) {
      final isTabActive = widget.tabController == null || widget.tabController!.index == 1;
      if (isTabActive) {
        if (!_hasInitialScrolled || _lastActiveIndex != activeIndex) {
          final isImmediate = !_hasInitialScrolled;
          _hasInitialScrolled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToActiveLine(activeIndex, isImmediate: isImmediate);
            }
          });
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Vertical padding allows both the first and last line to sit right in the center of the viewport
        final verticalPadding = constraints.maxHeight * 0.42;

        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            // When user scrolls manually, pause auto-scroll temporarily so it doesn't fight the user's gesture
            if (notification.direction != ScrollDirection.idle) {
              _isUserScrolling = true;
              _userScrollResumeTimer?.cancel();
              _userScrollResumeTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _isUserScrolling = false;
                    _lastActiveIndex = -1; // Trigger immediate re-centering
                  });
                }
              });
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(lyrics.length, (index) {
                _itemKeys[index] ??= GlobalKey();
                final line = lyrics[index];
                final isActive = index == activeIndex;
                final isPassed = activeIndex != -1 && index < activeIndex;

                return GestureDetector(
                  key: _itemKeys[index],
                  onTap: () {
                    // Tap any lyric to seek to that line and center immediately
                    _isUserScrolling = false;
                    _userScrollResumeTimer?.cancel();
                    widget.player.seekTo(line.timestamp);
                    _lastActiveIndex = -1;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _scrollToActiveLine(index);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: EdgeInsets.symmetric(
                      horizontal: isActive ? 16 : 8,
                      vertical: isActive ? 12 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isActive
                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.4)
                          : null,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primary
                            : (isPassed
                                ? Colors.white.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.28)),
                        fontSize: isActive ? 26 : (isPassed ? 18 : 17),
                        fontWeight: isActive ? FontWeight.w900 : (isPassed ? FontWeight.w600 : FontWeight.w500),
                        height: 1.35,
                        shadows: isActive
                            ? [
                                Shadow(
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      child: Text(line.text),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
