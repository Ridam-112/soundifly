import 'media_session_stub.dart'
    if (dart.library.js_interop) 'media_session_web.dart'
    as platform;

class MediaSessionService {
  static void init({
    required Function() onPlay,
    required Function() onPause,
    required Function() onNext,
    required Function() onPrevious,
    required Function(double seconds) onSeek,
  }) {
    platform.initMediaSession(
      onPlay: onPlay,
      onPause: onPause,
      onNext: onNext,
      onPrevious: onPrevious,
      onSeek: onSeek,
    );
  }

  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
    String? artworkUrl,
  }) {
    platform.updateMediaMetadata(
      title: title,
      artist: artist,
      album: album,
      artworkUrl: artworkUrl ?? '',
    );
  }

  static void updatePlaybackState({required bool isPlaying}) {
    platform.updateMediaPlaybackState(isPlaying: isPlaying);
  }

  static void updatePositionState({
    required double durationSeconds,
    required double positionSeconds,
  }) {
    platform.updateMediaPositionState(
      durationSeconds: durationSeconds,
      positionSeconds: positionSeconds,
    );
  }
}
