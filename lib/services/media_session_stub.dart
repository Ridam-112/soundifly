void initMediaSession({
  required Function() onPlay,
  required Function() onPause,
  required Function() onNext,
  required Function() onPrevious,
  required Function(double seconds) onSeek,
}) {}

void updateMediaMetadata({
  required String title,
  required String artist,
  required String album,
  required String artworkUrl,
}) {}

void updateMediaPlaybackState({required bool isPlaying}) {}

void updateMediaPositionState({
  required double durationSeconds,
  required double positionSeconds,
}) {}
