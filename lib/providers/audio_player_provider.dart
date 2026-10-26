import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../models/lyrics_model.dart';
import '../services/lyrics_service.dart';
import '../services/media_session_service.dart';
import '../services/supabase_music_sync_service.dart';
import '../services/yt_music_service.dart';
import '../services/audio_stream_resolver.dart';

enum LoopMode { off, all, one }

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  final bool _isBuffering = false;
  String? _playbackErrorMessage;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Live Lyrics State (Phase 5)
  ParsedLyrics _currentLyrics = ParsedLyrics.empty;
  int _activeLyricIndex = -1;
  bool _isLoadingLyrics = false;
  bool _miniPlayerLyricsMode = false;
  String? _lastNotificationLyric;

  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  double _volume = 1.0;
  bool _autoplay = true;

  /// Configurable playback threshold before recording listening history
  static const Duration playbackHistoryThreshold = Duration(seconds: 10);
  bool _historyRecordedForCurrentTrack = false;

  /// Monotonically increasing session ID to prevent out-of-order / racing audio playback
  int _playSessionId = 0;

  // External synchronized YouTube video controller bridge
  bool _isExternalVideoPlayback = false;
  bool get isExternalVideoPlayback => _isExternalVideoPlayback;
  void Function(bool play)? onExternalPlayPauseRequested;
  void Function(Duration position)? onExternalSeekRequested;

  void attachExternalVideoController({
    required void Function(bool play) onPlayPause,
    required void Function(Duration position) onSeek,
  }) {
    _isExternalVideoPlayback = true;
    onExternalPlayPauseRequested = onPlayPause;
    onExternalSeekRequested = onSeek;
  }

  void detachExternalVideoController() {
    _isExternalVideoPlayback = false;
    onExternalPlayPauseRequested = null;
    onExternalSeekRequested = null;
  }

  void updateFromExternalVideo({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    bool isLoading = false,
  }) {
    _isPlaying = isPlaying;
    _isLoading = isLoading;
    _playbackErrorMessage = null;
    _currentPosition = position;
    if (duration > Duration.zero) {
      _totalDuration = duration;
    }

    _updateActiveLyricIndex(position);

    MediaSessionService.updatePlaybackState(
      isPlaying: isPlaying,
      position: position,
      duration: _totalDuration,
      isLoading: isLoading,
    );

    notifyListeners();
  }

  // Real-time synchronization callback for Listen Together room
  void Function(Song? song, bool isPlaying, Duration position)? onPlaybackStateChanged;

  AudioPlayerProvider() {
    _initAudioPlayer();
    _currentSong = null;
    _queue = [];
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isBuffering => _isBuffering;
  String? get playbackErrorMessage => _playbackErrorMessage;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  double get volume => _volume;
  bool get autoplay => _autoplay;

  void setAutoplay(bool value) {
    _autoplay = value;
    notifyListeners();
  }

  // Live Lyrics Getters (Phase 5)
  ParsedLyrics get currentLyrics => _currentLyrics;
  int get activeLyricIndex => _activeLyricIndex;
  LyricLine? get activeLyricLine => (_activeLyricIndex >= 0 && _activeLyricIndex < _currentLyrics.lines.length)
      ? _currentLyrics.lines[_activeLyricIndex]
      : null;
  bool get isLoadingLyrics => _isLoadingLyrics;
  bool get miniPlayerLyricsMode => _miniPlayerLyricsMode;

  void clearPlaybackError() {
    _playbackErrorMessage = null;
    notifyListeners();
  }

  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    final val = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  void _initAudioPlayer() {
    try {
      _player.setReleaseMode(ReleaseMode.stop);
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {},
          ),
        ),
      );
    } catch (e) {
      debugPrint('AudioContext configuration note: $e');
    }

    MediaSessionService.init(
      onPlay: () {
        if (!_isPlaying) togglePlayPause();
      },
      onPause: () {
        if (_isPlaying) togglePlayPause();
      },
      onNext: () {
        next();
      },
      onPrevious: () {
        previous();
      },
      onSeek: (seconds) {
        seekTo(Duration(milliseconds: (seconds * 1000).toInt()));
      },
    );

    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      if (_isPlaying) {
        _isLoading = false;
        _playbackErrorMessage = null;
      }
      MediaSessionService.updatePlaybackState(
        isPlaying: _isPlaying,
        position: _currentPosition,
        duration: _totalDuration,
        isLoading: _isLoading,
      );
      notifyListeners();
      _broadcastSync();
    });

    _player.onPositionChanged.listen((pos) {
      final oldStep = _currentPosition.inMilliseconds ~/ 300;
      final newStep = pos.inMilliseconds ~/ 300;
      _currentPosition = pos;

      // Update Phase 5 Live Lyrics active index & media notification
      _updateActiveLyricIndex(pos);

      // Check playback threshold before recording listening history (e.g., 10 seconds of active playback)
      if (!_historyRecordedForCurrentTrack &&
          _currentSong != null &&
          pos >= playbackHistoryThreshold) {
        _historyRecordedForCurrentTrack = true;
        SupabaseMusicSyncService.recordListeningHistory(_currentSong!);
      }

      if (oldStep != newStep) {
        MediaSessionService.updatePositionState(
          durationSeconds: _totalDuration.inMilliseconds / 1000.0,
          positionSeconds: pos.inMilliseconds / 1000.0,
          isPlaying: _isPlaying,
        );
        notifyListeners();
      }
    });

    _player.onDurationChanged.listen((dur) {
      if (dur > Duration.zero) {
        _totalDuration = dur;
        MediaSessionService.updatePositionState(
          durationSeconds: dur.inMilliseconds / 1000.0,
          positionSeconds: _currentPosition.inMilliseconds / 1000.0,
          isPlaying: _isPlaying,
        );
        notifyListeners();
      }
    });

    _player.onPlayerComplete.listen((_) {
      _historyRecordedForCurrentTrack = false;
      _handleSongComplete();
    });
  }

  void _handleSongComplete() {
    if (_loopMode == LoopMode.one) {
      seekTo(Duration.zero);
      _player.resume();
    } else {
      next();
    }
  }

  Future<void> playSong(Song song, {List<Song>? playlist, int? startIndex}) async {
    // Generate new unique session ID to instantly cancel any previous pending/slow song requests
    final sessionId = ++_playSessionId;

    // Immediately halt previous player output to prevent audio overlap or ghost playback
    try {
      await _player.stop();
    } catch (_) {}
    if (sessionId != _playSessionId) return;

    if (playlist != null && playlist.isNotEmpty) {
      _queue = List.from(playlist);
      _currentIndex = startIndex ?? _queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex == -1) _currentIndex = 0;
    } else if (!_queue.any((s) => s.id == song.id)) {
      _queue.insert(_currentIndex + 1, song);
      _currentIndex = _currentIndex + 1;
    } else {
      _currentIndex = _queue.indexWhere((s) => s.id == song.id);
    }

    _currentSong = song;
    _totalDuration = song.duration;
    _currentPosition = Duration.zero;
    _currentLyrics = ParsedLyrics.empty;
    _activeLyricIndex = -1;
    _lastNotificationLyric = null;
    _isLoading = true;
    _playbackErrorMessage = null;
    _historyRecordedForCurrentTrack = false;

    MediaSessionService.updateMetadata(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album.isNotEmpty ? song.album : 'Soundifly',
      artworkUrl: song.coverUrl,
      duration: song.duration,
    );
    MediaSessionService.updatePlaybackState(
      isPlaying: true,
      position: Duration.zero,
      duration: song.duration,
      isLoading: true,
    );

    notifyListeners();

    try {
      final playableUrl = await AudioStreamResolver.resolveStreamUrl(song);
      // Abort immediately if user switched to another track while resolving
      if (sessionId != _playSessionId) {
        debugPrint('[AudioPlayerProvider] Discarding resolve for "${song.title}" (stale session $sessionId)');
        return;
      }

      debugPrint('[AudioPlayerProvider] Starting playback: $playableUrl');
      final mime = (playableUrl.contains('.mp4') || playableUrl.contains('mime=audio%2Fmp4')) ? 'audio/mp4' : null;
      await _player.play(UrlSource(playableUrl, mimeType: mime));

      // Re-verify after async play call finishes
      if (sessionId != _playSessionId) {
        debugPrint('[AudioPlayerProvider] Stopping stale playback after play finished for "${song.title}"');
        await _player.stop();
        return;
      }

      _isPlaying = true;
      _isLoading = false;
      _playbackErrorMessage = null;
      onExternalPlayPauseRequested?.call(true);
      notifyListeners();
      _playbackErrorMessage = null;
    } catch (e) {
      if (sessionId != _playSessionId) return;
      debugPrint('[AudioPlayerProvider] Initial play attempt failed: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 150));
        if (sessionId != _playSessionId) return;

        final fallbackUrl = await AudioStreamResolver.resolveFallbackStreamUrl(song);
        if (sessionId != _playSessionId) return;

        if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
          debugPrint('[AudioPlayerProvider] Playing smart fallback URL: $fallbackUrl');
          final mime = (fallbackUrl.contains('.mp4') || fallbackUrl.contains('mime=audio%2Fmp4')) ? 'audio/mp4' : null;
          await _player.play(UrlSource(fallbackUrl, mimeType: mime));
          if (sessionId != _playSessionId) {
            await _player.stop();
            return;
          }
          _isPlaying = true;
          _isLoading = false;
          _playbackErrorMessage = null;
        } else {
          final retryUrl = await AudioStreamResolver.resolveStreamUrl(song);
          if (sessionId != _playSessionId) return;
          await _player.play(UrlSource(retryUrl));
          if (sessionId != _playSessionId) {
            await _player.stop();
            return;
          }
          _isPlaying = true;
          _isLoading = false;
          _playbackErrorMessage = null;
        }
      } catch (err2) {
        if (sessionId != _playSessionId) return;
        debugPrint('Second play attempt error: $err2');
        _isPlaying = false;
        _isLoading = false;
        _playbackErrorMessage = 'Could not load audio. Please tap to try again.';
      }
    }

    if (sessionId != _playSessionId) return;
    notifyListeners();
    _broadcastSync();

    // Dynamically fetch synchronized LRC lyrics
    loadLyricsForCurrentSong();
  }

  void toggleMiniPlayerLyricsMode() {
    _miniPlayerLyricsMode = !_miniPlayerLyricsMode;
    notifyListeners();
  }

  void setMiniPlayerLyricsMode(bool enabled) {
    _miniPlayerLyricsMode = enabled;
    notifyListeners();
  }

  Future<void> loadLyricsForCurrentSong({bool forceRefresh = false}) async {
    final song = _currentSong;
    if (song == null) return;

    _isLoadingLyrics = true;
    _activeLyricIndex = -1;
    notifyListeners();

    try {
      final lyrics = await LyricsService.getLyrics(song, forceRefresh: forceRefresh);
      if (_currentSong?.id == song.id) {
        _currentLyrics = lyrics;
        _isLoadingLyrics = false;
        _updateActiveLyricIndex(_currentPosition);
        if (lyrics.lines.isNotEmpty) {
          _currentSong = _currentSong!.copyWith(lyrics: lyrics.lines);
        }
        notifyListeners();
      }
    } catch (e) {
      if (_currentSong?.id == song.id) {
        _isLoadingLyrics = false;
        notifyListeners();
      }
    }
  }

  void _updateActiveLyricIndex(Duration pos) {
    if (_currentLyrics.lines.isEmpty) {
      if (_activeLyricIndex != -1) {
        _activeLyricIndex = -1;
      }
      return;
    }

    final newIndex = _currentLyrics.findActiveIndex(pos);
    if (newIndex != _activeLyricIndex) {
      _activeLyricIndex = newIndex;
      // Update media notification lyrics if a valid line is reached (Phase 5 requirement)
      if (_currentSong != null &&
          _activeLyricIndex >= 0 &&
          _activeLyricIndex < _currentLyrics.lines.length) {
        final lyricText = _currentLyrics.lines[_activeLyricIndex].text;
        if (_lastNotificationLyric != lyricText) {
          _lastNotificationLyric = lyricText;
          MediaSessionService.updateMetadata(
            id: _currentSong!.id,
            title: _currentSong!.title,
            artist: _currentSong!.artist,
            album: '♪ $lyricText',
            artworkUrl: _currentSong!.coverUrl,
            duration: _totalDuration,
          );
        }
      }
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null && _queue.isNotEmpty) {
      await playSong(_queue.first);
      return;
    }

    if (_isPlaying) {
      await _player.pause();
      _isPlaying = false;
      onExternalPlayPauseRequested?.call(false);
      MediaSessionService.updatePlaybackState(
        isPlaying: false,
        position: _currentPosition,
        duration: _totalDuration,
      );
    } else {
      await _player.resume();
      _isPlaying = true;
      onExternalPlayPauseRequested?.call(true);
      MediaSessionService.updatePlaybackState(
        isPlaying: true,
        position: _currentPosition,
        duration: _totalDuration,
      );
    }
    notifyListeners();
    _broadcastSync();
  }

  Future<void> seekTo(Duration position) async {
    _currentPosition = position;
    MediaSessionService.updatePositionState(
      durationSeconds: _totalDuration.inMilliseconds / 1000.0,
      positionSeconds: position.inMilliseconds / 1000.0,
      isPlaying: _isPlaying,
    );
    notifyListeners();

    onExternalSeekRequested?.call(position);

    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Seek error: $e');
    }
    _broadcastSync();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    if (_isShuffle && _queue.length > 1) {
      int nextIdx;
      do {
        nextIdx = Random().nextInt(_queue.length);
      } while (nextIdx == _currentIndex);
      _currentIndex = nextIdx;
    } else if (!_isShuffle) {
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
      } else if (_loopMode == LoopMode.all) {
        _currentIndex = 0;
      } else if (_autoplay && _currentSong != null) {
        final currentArtist = _currentSong!.artist;
        final existingIds = _queue.map((s) => s.id).toSet();
        try {
          final recommended = await YTMusicService.search(currentArtist);
          final newTracks = recommended.where((s) => !existingIds.contains(s.id)).take(5).toList();
          if (newTracks.isNotEmpty) {
            _queue.addAll(newTracks);
            _currentIndex++;
            notifyListeners();
            await playSong(_queue[_currentIndex]);
            return;
          }
        } catch (_) {}
        await _player.stop();
        _isPlaying = false;
        notifyListeners();
        return;
      } else {
        await _player.stop();
        _isPlaying = false;
        notifyListeners();
        return;
      }
    }

    final nextSong = _queue[_currentIndex];
    await playSong(nextSong);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_currentPosition.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    if (_isShuffle && _queue.length > 1) {
      int prevIdx;
      do {
        prevIdx = Random().nextInt(_queue.length);
      } while (prevIdx == _currentIndex);
      _currentIndex = prevIdx;
    } else if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = _queue.length - 1;
    }

    final prevSong = _queue[_currentIndex];
    await playSong(prevSong);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void cycleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void playNext(Song song) {
    if (_queue.isEmpty) {
      _queue.add(song);
    } else {
      _queue.insert(_currentIndex + 1, song);
    }
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      }
      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    notifyListeners();
  }

  void clearQueue() {
    if (_currentSong != null) {
      _queue = [_currentSong!];
      _currentIndex = 0;
    } else {
      _queue.clear();
      _currentIndex = 0;
    }
    notifyListeners();
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    _player.setVolume(_volume);
    notifyListeners();
  }

  // Method called from Listen Together room to sync external state
  void syncFromRemote({required Song song, required bool isPlaying, required Duration position}) async {
    _currentSong = song;
    _currentPosition = position;
    _isPlaying = isPlaying;
    notifyListeners();

    try {
      if (isPlaying) {
        await _player.play(UrlSource(song.audioUrl));
        await _player.seek(position);
      } else {
        await _player.pause();
        await _player.seek(position);
      }
    } catch (e) {
      debugPrint('Sync remote error: $e');
    }
  }

  /// Resets all playback state, pauses/stops audio, and clears background media session.
  /// Used upon user sign-out, session teardown, or account switching.
  Future<void> resetPlayback() async {
    _currentSong = null;
    _isPlaying = false;
    _isLoading = false;
    _playbackErrorMessage = null;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _currentLyrics = ParsedLyrics.empty;
    _activeLyricIndex = -1;
    _lastNotificationLyric = null;
    _queue = [];
    _currentIndex = 0;
    _historyRecordedForCurrentTrack = false;
    MediaSessionService.clear();
    notifyListeners();

    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping player on reset: $e');
    }
  }

  void _broadcastSync() {
    if (onPlaybackStateChanged != null) {
      onPlaybackStateChanged!(_currentSong, _isPlaying, _currentPosition);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
