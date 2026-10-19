import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/search_result.dart';
import '../services/yt_music_service.dart';
import '../services/music_cache_service.dart';
import '../data/authorized_tracks.dart';

abstract class MusicRepository {
  Future<SearchResult> search(String query, {String filter = 'All'});
  Future<List<String>> getSuggestions(String query);
  Future<List<Song>> getTrending();
  Future<Artist?> getArtist(String artistId);
  Future<Album?> getAlbum(String albumId);
  Future<List<Song>> getAuthorizedDemoTracks();
}

class SoundiflyMusicRepository implements MusicRepository {
  @override
  Future<SearchResult> search(String query, {String filter = 'All'}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return SearchResult.empty;

    final cacheKey = '$cleanQuery::$filter';
    final cached = MusicCacheService.getSearchResult(cacheKey);
    if (cached != null) return cached;

    List<Song> songs = [];
    List<Artist> matchingArtists = [];
    List<Album> matchingAlbums = [];

    final qLower = cleanQuery.toLowerCase();

    // 1. Fetch matching Artists from catalog
    if (filter == 'All' || filter == 'Artists') {
      matchingArtists = AuthorizedMusicCatalog.artists.where((a) {
        return a.name.toLowerCase().contains(qLower) ||
            a.genres.any((g) => g.toLowerCase().contains(qLower));
      }).toList();
    }

    // 2. Fetch matching Albums from catalog
    if (filter == 'All' || filter == 'Albums') {
      matchingAlbums = AuthorizedMusicCatalog.albums.where((alb) {
        return alb.title.toLowerCase().contains(qLower) ||
            alb.artist.toLowerCase().contains(qLower) ||
            alb.genre.toLowerCase().contains(qLower);
      }).toList();
    }

    // 3. Fetch songs from API and fallback catalog
    if (filter == 'All' || filter == 'Songs') {
      // First check local authorized catalog for immediate matches
      final localMatches = AuthorizedMusicCatalog.demoAuthorizedSongs.where((s) {
        return s.title.toLowerCase().contains(qLower) ||
            s.artist.toLowerCase().contains(qLower) ||
            s.album.toLowerCase().contains(qLower);
      }).toList();

      try {
        final apiSongs = await YTMusicService.search(cleanQuery);
        // Deduplicate and combine
        final Set<String> seenIds = {};
        for (final s in localMatches) {
          seenIds.add(s.id);
          songs.add(s);
        }
        for (final s in apiSongs) {
          if (!seenIds.contains(s.id)) {
            seenIds.add(s.id);
            songs.add(s);
          }
        }
      } catch (_) {
        songs = localMatches.isNotEmpty ? localMatches : AuthorizedMusicCatalog.demoAuthorizedSongs;
      }
    }

    final result = SearchResult(
      query: cleanQuery,
      songs: songs,
      artists: matchingArtists,
      albums: matchingAlbums,
    );

    MusicCacheService.cacheSearchResult(cacheKey, result);
    return result;
  }

  @override
  Future<List<String>> getSuggestions(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final suggestions = await YTMusicService.getSuggestions(cleanQuery);
      if (suggestions.isNotEmpty) return suggestions;
    } catch (_) {}

    // Fallback local suggestions
    final qLower = cleanQuery.toLowerCase();
    final localSuggs = <String>{};

    for (final s in AuthorizedMusicCatalog.demoAuthorizedSongs) {
      if (s.title.toLowerCase().contains(qLower)) localSuggs.add(s.title);
      if (s.artist.toLowerCase().contains(qLower)) localSuggs.add(s.artist);
    }
    for (final a in AuthorizedMusicCatalog.artists) {
      if (a.name.toLowerCase().contains(qLower)) localSuggs.add(a.name);
    }

    return localSuggs.take(6).toList();
  }

  @override
  Future<List<Song>> getTrending() async {
    try {
      final apiSongs = await YTMusicService.getTrending();
      if (apiSongs.isNotEmpty) return apiSongs;
    } catch (_) {}

    return AuthorizedMusicCatalog.demoAuthorizedSongs;
  }

  @override
  Future<Artist?> getArtist(String artistId) async {
    final cached = MusicCacheService.getArtist(artistId);
    if (cached != null) return cached;

    final found = AuthorizedMusicCatalog.artists.firstWhere(
      (a) => a.id == artistId,
      orElse: () => Artist(
        id: artistId,
        name: 'Featured Artist',
        imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
        genres: ['Music'],
        topSongs: AuthorizedMusicCatalog.demoAuthorizedSongs.take(3).toList(),
      ),
    );

    MusicCacheService.cacheArtist(found);
    return found;
  }

  @override
  Future<Album?> getAlbum(String albumId) async {
    final cached = MusicCacheService.getAlbum(albumId);
    if (cached != null) return cached;

    final found = AuthorizedMusicCatalog.albums.firstWhere(
      (a) => a.id == albumId,
      orElse: () => Album(
        id: albumId,
        title: 'Featured Album',
        artist: 'Various Artists',
        coverUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=600&auto=format&fit=crop&q=80',
        releaseYear: '2026',
        tracks: AuthorizedMusicCatalog.demoAuthorizedSongs.take(4).toList(),
      ),
    );

    MusicCacheService.cacheAlbum(found);
    return found;
  }

  @override
  Future<List<Song>> getAuthorizedDemoTracks() async {
    return AuthorizedMusicCatalog.demoAuthorizedSongs;
  }
}
