import 'package:audio_service/audio_service.dart';

SoundiflyAudioHandler? globalAudioHandler;

class SoundiflyAudioHandler extends BaseAudioHandler with SeekHandler {
  void Function()? onPlayCallback;
  void Function()? onPauseCallback;
  void Function()? onNextCallback;
  void Function()? onPreviousCallback;
  void Function(Duration position)? onSeekCallback;

  static const Set<MediaAction> _defaultActions = {
    MediaAction.play,
    MediaAction.pause,
    MediaAction.playPause,
    MediaAction.stop,
    MediaAction.skipToNext,
    MediaAction.skipToPrevious,
    MediaAction.seek,
    MediaAction.seekForward,
    MediaAction.seekBackward,
  };

  SoundiflyAudioHandler() {
    playbackState.add(PlaybackState(
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: _defaultActions,
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
    ));
  }

  void updateTrackMetadata({
    required String id,
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    String? artworkUrl,
  }) {
    Uri? parsedUri;
    if (artworkUrl != null && artworkUrl.isNotEmpty) {
      if (artworkUrl.startsWith('http://') ||
          artworkUrl.startsWith('https://') ||
          artworkUrl.startsWith('file://')) {
        parsedUri = Uri.tryParse(artworkUrl);
      }
    }

    mediaItem.add(MediaItem(
      id: id,
      album: album,
      title: title,
      artist: artist,
      duration: duration,
      artUri: parsedUri,
      playable: true,
    ));
  }

  void updateState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    bool isLoading = false,
  }) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: _defaultActions,
      androidCompactActionIndices: const [0, 1, 2],
      processingState: isLoading
          ? AudioProcessingState.buffering
          : AudioProcessingState.ready,
      playing: isPlaying,
      updatePosition: position,
      bufferedPosition: position,
      speed: 1.0,
    ));
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    // Responds to Bluetooth earbuds / wired headphones single/double/triple taps
    switch (button) {
      case MediaButton.media:
        if (playbackState.value.playing) {
          await pause();
        } else {
          await play();
        }
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  @override
  Future<void> play() async {
    onPlayCallback?.call();
  }

  @override
  Future<void> pause() async {
    onPauseCallback?.call();
  }

  @override
  Future<void> skipToNext() async {
    onNextCallback?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onPreviousCallback?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    onSeekCallback?.call(position);
  }

  @override
  Future<void> fastForward() async {
    final newPos = playbackState.value.position + const Duration(seconds: 10);
    await seek(newPos);
  }

  @override
  Future<void> rewind() async {
    final pos = playbackState.value.position - const Duration(seconds: 10);
    await seek(pos < Duration.zero ? Duration.zero : pos);
  }

  @override
  Future<void> stop() async {
    onPauseCallback?.call();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();
  }

  void clearState() {
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: _defaultActions,
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
    ));
  }
}
