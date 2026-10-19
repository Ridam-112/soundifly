import 'dart:js_interop';

@JS('soundiflyMediaSession.init')
external void _jsInit(
  JSFunction onPlay,
  JSFunction onPause,
  JSFunction onNext,
  JSFunction onPrev,
  JSFunction onSeek,
);

@JS('soundiflyMediaSession.updateMetadata')
external void _jsUpdateMetadata(
  JSString title,
  JSString artist,
  JSString album,
  JSString artworkUrl,
);

@JS('soundiflyMediaSession.setPlaybackState')
external void _jsSetPlaybackState(JSString state);

@JS('soundiflyMediaSession.setPositionState')
external void _jsSetPositionState(JSNumber durationSeconds, JSNumber positionSeconds);

void initMediaSession({
  required Function() onPlay,
  required Function() onPause,
  required Function() onNext,
  required Function() onPrevious,
  required Function(double seconds) onSeek,
}) {
  try {
    final playJs = (() {
      onPlay();
    }).toJS;

    final pauseJs = (() {
      onPause();
    }).toJS;

    final nextJs = (() {
      onNext();
    }).toJS;

    final prevJs = (() {
      onPrevious();
    }).toJS;

    final seekJs = ((JSNumber seconds) {
      onSeek(seconds.toDartDouble);
    }).toJS;

    _jsInit(playJs, pauseJs, nextJs, prevJs, seekJs);
  } catch (e) {
    // Ignored if mediaSession unavailable
  }
}

void updateMediaMetadata({
  required String title,
  required String artist,
  required String album,
  required String artworkUrl,
}) {
  try {
    _jsUpdateMetadata(
      title.toJS,
      artist.toJS,
      album.toJS,
      artworkUrl.toJS,
    );
  } catch (e) {
    // Ignored
  }
}

void updateMediaPlaybackState({required bool isPlaying}) {
  try {
    _jsSetPlaybackState((isPlaying ? 'playing' : 'paused').toJS);
  } catch (e) {
    // Ignored
  }
}

void updateMediaPositionState({
  required double durationSeconds,
  required double positionSeconds,
}) {
  try {
    _jsSetPositionState(
      durationSeconds.toJS,
      positionSeconds.toJS,
    );
  } catch (e) {
    // Ignored
  }
}
