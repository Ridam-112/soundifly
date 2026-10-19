import 'song.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String releaseYear;
  final String genre;
  final List<Song> tracks;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.releaseYear,
    this.genre = 'Music',
    this.tracks = const [],
  });

  Duration get totalDuration {
    return tracks.fold<Duration>(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );
  }

  String get formattedTotalDuration {
    final minutes = totalDuration.inMinutes;
    return '$minutes mins';
  }

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    String? coverUrl,
    String? releaseYear,
    String? genre,
    List<Song>? tracks,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      releaseYear: releaseYear ?? this.releaseYear,
      genre: genre ?? this.genre,
      tracks: tracks ?? this.tracks,
    );
  }
}
