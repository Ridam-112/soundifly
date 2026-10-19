import 'song.dart';

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String bio;
  final int monthlyListeners;
  final List<String> genres;
  final List<Song> topSongs;

  const Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bio = '',
    this.monthlyListeners = 0,
    this.genres = const [],
    this.topSongs = const [],
  });

  String get formattedListeners {
    if (monthlyListeners >= 1000000) {
      return '${(monthlyListeners / 1000000).toStringAsFixed(1)}M monthly listeners';
    } else if (monthlyListeners >= 1000) {
      return '${(monthlyListeners / 1000).toStringAsFixed(1)}K monthly listeners';
    }
    return '$monthlyListeners monthly listeners';
  }

  Artist copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? bio,
    int? monthlyListeners,
    List<String>? genres,
    List<Song>? topSongs,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      monthlyListeners: monthlyListeners ?? this.monthlyListeners,
      genres: genres ?? this.genres,
      topSongs: topSongs ?? this.topSongs,
    );
  }
}
