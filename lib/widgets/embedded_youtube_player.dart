import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../providers/audio_player_provider.dart';
import '../theme/app_theme.dart';

class EmbeddedYoutubePlayer extends StatefulWidget {
  final String videoId;
  final double width;
  final double height;
  final VoidCallback? onClose;

  const EmbeddedYoutubePlayer({
    super.key,
    required this.videoId,
    this.width = 320,
    this.height = 320,
    this.onClose,
  });

  @override
  State<EmbeddedYoutubePlayer> createState() => _EmbeddedYoutubePlayerState();
}

class _EmbeddedYoutubePlayerState extends State<EmbeddedYoutubePlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final player = context.read<AudioPlayerProvider>();
    player.attachExternalVideoController(
      onPlayPause: (play) {
        if (play) {
          _controller.runJavaScript('window.externalPlay && window.externalPlay();');
        } else {
          _controller.runJavaScript('window.externalPause && window.externalPause();');
        }
      },
      onSeek: (pos) {
        final sec = pos.inMilliseconds / 1000.0;
        _controller.runJavaScript('window.externalSeek && window.externalSeek($sec);');
      },
    );
  }

  @override
  void didUpdateWidget(covariant EmbeddedYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _loadVideo();
    }
  }

  @override
  void dispose() {
    try {
      context.read<AudioPlayerProvider>().detachExternalVideoController();
    } catch (_) {}
    super.dispose();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
              final player = context.read<AudioPlayerProvider>();
              final curSec = player.currentPosition.inMilliseconds / 1000.0;
              if (curSec > 0) {
                _controller.runJavaScript('window.externalSeek && window.externalSeek($curSec);');
              }
              if (!player.isPlaying) {
                _controller.runJavaScript('window.externalPause && window.externalPause();');
              }
            }
          },
        ),
      );

    // Disable gesture requirement so video autoplays on its own immediately
    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    _loadVideo();
  }

  void _loadVideo() {
    final cleanId = widget.videoId.trim();
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body, html { width: 100%; height: 100%; background: #000; overflow: hidden; display: flex; align-items: center; justify-content: center; }
    #player { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    var ytPlayer;
    function onYouTubeIframeAPIReady() {
      ytPlayer = new YT.Player('player', {
        height: '100%',
        width: '100%',
        videoId: '$cleanId',
        playerVars: {
          'autoplay': 1,
          'playsinline': 1,
          'controls': 0,
          'disablekb': 1,
          'fs': 0,
          'mute': 1,
          'modestbranding': 1,
          'rel': 0,
          'origin': 'https://v5.mp3paw.link'
        },
        events: {
          'onReady': onPlayerReady
        }
      });
    }

    function onPlayerReady(event) {
      event.target.mute();
      event.target.playVideo();
    }

    window.externalPlay = function() {
      if (ytPlayer && ytPlayer.playVideo) {
        ytPlayer.mute();
        ytPlayer.playVideo();
      }
    };
    window.externalPause = function() {
      if (ytPlayer && ytPlayer.pauseVideo) ytPlayer.pauseVideo();
    };
    window.externalSeek = function(sec) {
      if (ytPlayer && ytPlayer.seekTo) ytPlayer.seekTo(sec, true);
    };
  </script>
</body>
</html>
''';

    _controller.loadHtmlString(html, baseUrl: 'https://v5.mp3paw.link');
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();

    return GestureDetector(
      onTap: () => player.togglePlayPause(),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Ignore direct webview touches so tapping toggles playback cleanly through Flutter
              IgnorePointer(
                ignoring: true,
                child: WebViewWidget(controller: _controller),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              if (widget.onClose != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
