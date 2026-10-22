import 'media_session_stub.dart'
    if (dart.library.js_interop) 'media_session_web.dart'
    as platform;
import 'soundifly_audio_handler.dart';

class MediaSessionService {
  static void init({
    required Function() onPlay,
    required Function() onPause,
    required Function() onNext,
    required Function() onPrevious,
    required Function(double seconds) onSeek,
  }) {
    // 1. Web MediaSession
    platform.initMediaSession(
      onPlay: onPlay,
      onPause: onPause,
      onNext: onNext,
      onPrevious: onPrevious,
      onSeek: onSeek,
    );

    // 2. Android / Mobile AudioService MediaSession
    if (globalAudioHandler != null) {
      globalAudioHandler!.onPlayCallback = onPlay;
      globalAudioHandler!.onPauseCallback = onPause;
      globalAudioHandler!.onNextCallback = onNext;
      globalAudioHandler!.onPreviousCallback = onPrevious;
      globalAudioHandler!.onSeekCallback = (pos) => onSeek(pos.inMilliseconds / 1000.0);
    }
  }

  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
    String? artworkUrl,
    Duration? duration,
    String? id,
  }) {
    platform.updateMediaMetadata(
      title: title,
      artist: artist,
      album: album,
      artworkUrl: artworkUrl ?? '',
    );

    globalAudioHandler?.updateTrackMetadata(
      id: id ?? globalAudioHandler?.mediaItem.value?.id ?? '${title}_$artist',
      title: title,
      artist: artist,
      album: album,
      duration: duration ?? globalAudioHandler?.mediaItem.value?.duration ?? Duration.zero,
      artworkUrl: artworkUrl ?? globalAudioHandler?.mediaItem.value?.artUri?.toString(),
    );
  }

  static void updatePlaybackState({
    required bool isPlaying,
    Duration? position,
    Duration? duration,
    bool isLoading = false,
  }) {
    platform.updateMediaPlaybackState(isPlaying: isPlaying);

    if (globalAudioHandler != null) {
      globalAudioHandler!.updateState(
        isPlaying: isPlaying,
        position: position ?? globalAudioHandler!.playbackState.value.position,
        duration: duration ?? (globalAudioHandler!.mediaItem.value?.duration ?? Duration.zero),
        isLoading: isLoading,
      );
    }
  }

  static void updatePositionState({
    required double durationSeconds,
    required double positionSeconds,
    bool? isPlaying,
  }) {
    platform.updateMediaPositionState(
      durationSeconds: durationSeconds,
      positionSeconds: positionSeconds,
    );

    if (globalAudioHandler != null) {
      final playing = isPlaying ?? globalAudioHandler!.playbackState.value.playing;
      globalAudioHandler!.updateState(
        isPlaying: playing,
        position: Duration(milliseconds: (positionSeconds * 1000).toInt()),
        duration: Duration(milliseconds: (durationSeconds * 1000).toInt()),
      );
    }
  }

  static void clear() {
    platform.updateMediaPlaybackState(isPlaying: false);
    globalAudioHandler?.clearState();
  }
}
