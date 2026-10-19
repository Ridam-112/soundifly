enum AudioSourceType {
  authorizedStream,
  demoSample,
  catalogMetadata,
}

class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final String audioUrl;
  final Duration duration;
  final String genre;
  final bool isExplicit;
  final int playsCount;
  final String releaseYear;
  final List<LyricLine> lyrics;
  final AudioSourceType sourceType;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.audioUrl,
    required this.duration,
    this.genre = 'Music',
    this.isExplicit = false,
    this.playsCount = 0,
    this.releaseYear = '2026',
    this.lyrics = const [],
    this.sourceType = AudioSourceType.authorizedStream,
  });

  bool get isPlayable => audioUrl.isNotEmpty;

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    String? audioUrl,
    Duration? duration,
    String? genre,
    bool? isExplicit,
    int? playsCount,
    String? releaseYear,
    List<LyricLine>? lyrics,
    AudioSourceType? sourceType,
  }) {
    return Song(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      isExplicit: isExplicit ?? this.isExplicit,
      playsCount: playsCount ?? this.playsCount,
      releaseYear: releaseYear ?? this.releaseYear,
      lyrics: lyrics ?? this.lyrics,
      sourceType: sourceType ?? this.sourceType,
    );
  }
}
