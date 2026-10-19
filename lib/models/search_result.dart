import 'song.dart';
import 'artist.dart';
import 'album.dart';

class SearchResult {
  final String query;
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;

  const SearchResult({
    required this.query,
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
  });

  bool get isEmpty => songs.isEmpty && artists.isEmpty && albums.isEmpty;
  bool get isNotEmpty => !isEmpty;

  static const SearchResult empty = SearchResult(query: '');
}
