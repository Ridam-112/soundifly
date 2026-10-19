import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/search_result.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

/// In-memory cache for music metadata, search queries, artists, and albums
class MusicCacheService {
  static final Map<String, _CacheEntry<SearchResult>> _searchCache = {};
  static final Map<String, _CacheEntry<Song>> _songCache = {};
  static final Map<String, _CacheEntry<Artist>> _artistCache = {};
  static final Map<String, _CacheEntry<Album>> _albumCache = {};

  static const Duration _searchTtl = Duration(minutes: 8);
  static const Duration _metadataTtl = Duration(hours: 1);

  // SEARCH CACHE
  static SearchResult? getSearchResult(String key) {
    final entry = _searchCache[key.trim().toLowerCase()];
    if (entry != null && !entry.isExpired(_searchTtl)) {
      return entry.data;
    }
    _searchCache.remove(key.trim().toLowerCase());
    return null;
  }

  static void cacheSearchResult(String key, SearchResult result) {
    _searchCache[key.trim().toLowerCase()] = _CacheEntry(result);
  }

  // SONG CACHE
  static Song? getSong(String songId) {
    final entry = _songCache[songId];
    if (entry != null && !entry.isExpired(_metadataTtl)) {
      return entry.data;
    }
    _songCache.remove(songId);
    return null;
  }

  static void cacheSong(Song song) {
    _songCache[song.id] = _CacheEntry(song);
  }

  // ARTIST CACHE
  static Artist? getArtist(String artistId) {
    final entry = _artistCache[artistId];
    if (entry != null && !entry.isExpired(_metadataTtl)) {
      return entry.data;
    }
    _artistCache.remove(artistId);
    return null;
  }

  static void cacheArtist(Artist artist) {
    _artistCache[artist.id] = _CacheEntry(artist);
  }

  // ALBUM CACHE
  static Album? getAlbum(String albumId) {
    final entry = _albumCache[albumId];
    if (entry != null && !entry.isExpired(_metadataTtl)) {
      return entry.data;
    }
    _albumCache.remove(albumId);
    return null;
  }

  static void cacheAlbum(Album album) {
    _albumCache[album.id] = _CacheEntry(album);
  }

  static void clearAll() {
    _searchCache.clear();
    _songCache.clear();
    _artistCache.clear();
    _albumCache.clear();
  }
}
