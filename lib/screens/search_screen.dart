import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/search_result.dart';
import '../repositories/music_repository.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/artist_detail_modal.dart';
import '../widgets/album_detail_modal.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final MusicRepository _repository = SoundiflyMusicRepository();
  Timer? _debounceTimer;

  String _query = '';
  bool _isLoading = false;
  String? _errorMessage;
  SearchResult _searchResult = SearchResult.empty;
  List<String> _suggestions = [];
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Songs', 'Artists', 'Albums'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    _debounceTimer?.cancel();
    setState(() {
      _query = val;
      _errorMessage = null;
    });

    if (val.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _searchResult = SearchResult.empty;
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final suggs = await _repository.getSuggestions(val);
        if (mounted) {
          setState(() {
            _suggestions = suggs;
          });
        }
      } catch (_) {}

      _performSearch(val);
    });
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repository.search(cleanQuery, filter: _selectedFilter);
      if (mounted) {
        setState(() {
          _searchResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not fetch search results. Check your connection.';
        });
      }
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    if (_query.trim().isNotEmpty) {
      _performSearch(_query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Search',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 14),

              // Search Input Field
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                onChanged: _onQueryChanged,
                onSubmitted: (q) => _performSearch(q),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // Live suggestions chips
              if (_suggestions.isNotEmpty && _query.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestions.length,
                    itemBuilder: (ctx, i) {
                      final sugg = _suggestions[i];
                      return GestureDetector(
                        onTap: () {
                          _searchCtrl.text = sugg;
                          _performSearch(sugg);
                          setState(() {
                            _query = sugg;
                            _suggestions = [];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.north_west_rounded, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(sugg, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Filter Chips
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (ctx, i) {
                    final f = _filters[i];
                    final isSelected = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () => _onFilterSelected(f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.white10,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Body: Loading, Error, Search Results, or Browse Categories
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _errorMessage != null
                        ? _buildErrorState()
                        : (_query.isNotEmpty
                            ? _buildSearchResults(player, playlistProv)
                            : _buildBrowseCategories(player)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Network error occurred',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            onPressed: () => _performSearch(_query),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AudioPlayerProvider player, PlaylistProvider playlistProv) {
    if (_searchResult.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              'No results found for "$_query"',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_selectedFilter == 'Artists') {
      return _buildArtistsGrid(_searchResult.artists);
    }

    if (_selectedFilter == 'Albums') {
      return _buildAlbumsGrid(_searchResult.albums);
    }

    if (_selectedFilter == 'Songs') {
      return _buildSongsList(_searchResult.songs, player, playlistProv);
    }

    // Default 'All' tab: Combined sections
    return CustomScrollView(
      slivers: [
        // Artists Horizontal Carousel
        if (_searchResult.artists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Artists', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${_searchResult.artists.length} found', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _searchResult.artists.length,
                itemBuilder: (ctx, idx) {
                  final artist = _searchResult.artists[idx];
                  return GestureDetector(
                    onTap: () => ArtistDetailModal.show(context, artist),
                    child: Container(
                      width: 105,
                      margin: const EdgeInsets.only(right: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.primaryOrange,
                            ),
                            child: ClipOval(
                              child: AppNetworkImage(
                                url: artist.imageUrl,
                                width: 72,
                                height: 72,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            artist.formattedListeners,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
        ],

        // Albums Horizontal Carousel
        if (_searchResult.albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Albums', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${_searchResult.albums.length} found', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _searchResult.albums.length,
                itemBuilder: (ctx, idx) {
                  final album = _searchResult.albums[idx];
                  return GestureDetector(
                    onTap: () => AlbumDetailModal.show(context, album),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppNetworkImage(
                              url: album.coverUrl,
                              width: 120,
                              height: 110,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            album.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            album.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
        ],

        // Songs Section Header
        if (_searchResult.songs.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Songs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

        // Songs List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, idx) {
              final song = _searchResult.songs[idx];
              return _buildSongTile(song, idx, _searchResult.songs, player, playlistProv);
            },
            childCount: _searchResult.songs.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }

  Widget _buildSongsList(List<Song> songs, AudioPlayerProvider player, PlaylistProvider playlistProv) {
    if (songs.isEmpty) {
      return const Center(child: Text('No songs found', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (ctx, idx) {
        final song = songs[idx];
        return _buildSongTile(song, idx, songs, player, playlistProv);
      },
    );
  }

  Widget _buildArtistsGrid(List<Artist> artists) {
    if (artists.isEmpty) {
      return const Center(child: Text('No artists found', style: TextStyle(color: AppColors.textMuted)));
    }
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 60),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: artists.length,
      itemBuilder: (ctx, idx) {
        final artist = artists[idx];
        return GestureDetector(
          onTap: () => ArtistDetailModal.show(context, artist),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: AppNetworkImage(
                    url: artist.imageUrl,
                    width: 76,
                    height: 76,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  artist.formattedListeners,
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsGrid(List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(child: Text('No albums found', style: TextStyle(color: AppColors.textMuted)));
    }
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 60),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: albums.length,
      itemBuilder: (ctx, idx) {
        final album = albums[idx];
        return GestureDetector(
          onTap: () => AlbumDetailModal.show(context, album),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppNetworkImage(
                      url: album.coverUrl,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${album.artist} • ${album.releaseYear}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongTile(
    Song song,
    int idx,
    List<Song> playlist,
    AudioPlayerProvider player,
    PlaylistProvider playlistProv,
  ) {
    final currentSongId = player.currentSong?.id;
    final isPlayingOverall = player.isPlaying;
    final isPlaying = currentSongId == song.id && isPlayingOverall;
    final isLiked = playlistProv.isSongLiked(song.id);
    final isThisLoading = player.isLoading && currentSongId == song.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isPlaying ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: isPlaying ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
      ),
      child: ListTile(
        leading: AppNetworkImage(
          url: song.coverUrl,
          width: 48,
          height: 48,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPlaying ? AppColors.primary : Colors.white,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${song.artist} • ${song.formattedDuration}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => playlistProv.toggleLikeSong(song),
            ),
            IconButton(
              icon: isThisLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppColors.primary,
                      size: 32,
                    ),
              onPressed: isThisLoading
                  ? null
                  : () {
                      if (isPlaying) {
                        player.togglePlayPause();
                      } else {
                        player.playSong(song, playlist: playlist, startIndex: idx);
                      }
                    },
            ),
          ],
        ),
        onTap: () {
          player.playSong(song, playlist: playlist, startIndex: idx);
        },
      ),
    );
  }

  Widget _buildBrowseCategories(AudioPlayerProvider player) {
    final categories = [
      {'title': 'Bangla Top Hits 🎸', 'query': 'Bangla top songs 2026', 'color1': 0xFFFF5500, 'color2': 0xFF992200},
      {'title': 'Arijit Singh Best ❤️', 'query': 'Arijit Singh hit songs', 'color1': 0xFFFF3366, 'color2': 0xFF880022},
      {'title': 'Shironamhin & Rock ⚡', 'query': 'Shironamhin best songs', 'color1': 0xFF6C5CE7, 'color2': 0xFF3D2085},
      {'title': 'Lo-Fi Chill & Study ☕', 'query': 'Lo-Fi beats chill music', 'color1': 0xFF00CEC9, 'color2': 0xFF0984E3},
      {'title': 'Gym & Workout Beast 🔥', 'query': 'Gym workout motivation songs', 'color1': 0xFFE17055, 'color2': 0xFFD63031},
      {'title': 'Romantic Couple Vibes ✨', 'query': 'Romantic love songs hindi bangla', 'color1': 0xFF2D3436, 'color2': 0xFF000000},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Categories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (ctx, idx) {
              final cat = categories[idx];
              return GestureDetector(
                onTap: () {
                  final q = cat['query'] as String;
                  _searchCtrl.text = q;
                  _onQueryChanged(q);
                  _performSearch(q);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Color(cat['color1'] as int), Color(cat['color2'] as int)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    cat['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
