import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/search_result.dart';
import '../services/yt_music_service.dart';
import '../services/music_cache_service.dart';
import '../data/music_onboarding_data.dart';
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
    final cleanQuery = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanQuery.isEmpty) return SearchResult.empty;

    final cacheKey = '$cleanQuery::$filter';
    final cached = MusicCacheService.getSearchResult(cacheKey);
    if (cached != null) return cached;

    List<Song> songs = [];
    List<Artist> matchingArtists = [];
    List<Album> matchingAlbums = [];

    // Search corresponding categories
    if (filter == 'All') {
      final results = await Future.wait([
        YTMusicService.search(cleanQuery),
        YTMusicService.searchArtists(cleanQuery),
        YTMusicService.searchAlbums(cleanQuery),
      ]);
      songs = results[0] as List<Song>;
      matchingArtists = results[1] as List<Artist>;
      matchingAlbums = results[2] as List<Album>;
    } else if (filter == 'Songs') {
      songs = await YTMusicService.search(cleanQuery);
    } else if (filter == 'Artists') {
      matchingArtists = await YTMusicService.searchArtists(cleanQuery);
    } else if (filter == 'Albums') {
      matchingAlbums = await YTMusicService.searchAlbums(cleanQuery);
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

    final localSuggs = <String>{};

    for (final a in MusicOnboardingData.curatedArtists) {
      if (a.matchesQuery(cleanQuery)) {
        localSuggs.add(a.name);
      }
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

    for (final ca in MusicOnboardingData.curatedArtists) {
      if (ca.id == artistId || ca.name.toLowerCase() == artistId.toLowerCase()) {
        final artist = Artist(
          id: ca.id,
          name: ca.name,
          imageUrl: ca.imageUrl,
          bio: '${ca.artistTypeDisplay} • ${ca.languages.join(", ")}',
          monthlyListeners: ca.popularityScore,
          genres: [ca.genre, ...ca.languages],
        );
        MusicCacheService.cacheArtist(artist);
        return artist;
      }
    }

    final list = await YTMusicService.searchArtists(artistId);
    if (list.isNotEmpty) {
      MusicCacheService.cacheArtist(list.first);
      return list.first;
    }

    return null;
  }

  @override
  Future<Album?> getAlbum(String albumId) async {
    final cached = MusicCacheService.getAlbum(albumId);
    if (cached != null && cached.tracks.isNotEmpty) return cached;

    final detailed = await YTMusicService.getAlbumDetails(albumId);
    if (detailed != null) {
      MusicCacheService.cacheAlbum(detailed);
      return detailed;
    }

    return cached;
  }

  @override
  Future<List<Song>> getAuthorizedDemoTracks() async {
    return AuthorizedMusicCatalog.demoAuthorizedSongs;
  }
}
