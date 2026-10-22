import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../data/music_onboarding_data.dart';
import '../../services/artist_discovery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';

class MusicOnboardingScreen extends StatefulWidget {
  final bool isEditingMode;
  final VoidCallback? onComplete;

  const MusicOnboardingScreen({
    super.key,
    this.isEditingMode = false,
    this.onComplete,
  });

  @override
  State<MusicOnboardingScreen> createState() => _MusicOnboardingScreenState();
}

class _MusicOnboardingScreenState extends State<MusicOnboardingScreen> {
  int _currentStep = 0; // 0 = Languages, 1 = Artists, 2 = Genres & Moods
  final Set<String> _selectedLanguages = {};
  final Set<String> _selectedArtists = {};
  final Set<String> _selectedGenres = {};

  final TextEditingController _languageSearchCtrl = TextEditingController();
  final TextEditingController _artistSearchCtrl = TextEditingController();

  String _languageFilter = '';
  String _artistFilter = '';
  String _activeLanguageFilter = 'All';
  bool _isSearchingArtists = false;
  List<OnboardingArtist> _discoveredArtists = [];
  Timer? _artistDebounceTimer;

  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate if editing existing preferences
    final existingSettings = context.read<UserSettingsProvider>().settings;
    if (existingSettings.preferredLanguages.isNotEmpty) {
      _selectedLanguages.addAll(existingSettings.preferredLanguages);
    }
    if (existingSettings.favoriteArtists.isNotEmpty) {
      _selectedArtists.addAll(existingSettings.favoriteArtists);
    }
    if (existingSettings.preferredGenres.isNotEmpty) {
      _selectedGenres.addAll(existingSettings.preferredGenres);
    }

    _languageSearchCtrl.addListener(() {
      setState(() {
        _languageFilter = _languageSearchCtrl.text.trim().toLowerCase();
      });
    });

    _artistSearchCtrl.addListener(_onArtistSearchChanged);
  }

  void _onArtistSearchChanged() {
    final query = _artistSearchCtrl.text.trim();
    _artistDebounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _artistFilter = '';
        _isSearchingArtists = false;
        _discoveredArtists = [];
      });
      return;
    }

    setState(() {
      _artistFilter = query;
      _isSearchingArtists = true;
    });

    _artistDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await ArtistDiscoveryService.searchArtists(
          query,
          preferredLanguages: _selectedLanguages.toList(),
        );
        if (mounted && _artistSearchCtrl.text.trim() == query) {
          setState(() {
            _discoveredArtists = results;
            _isSearchingArtists = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSearchingArtists = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _artistDebounceTimer?.cancel();
    _languageSearchCtrl.dispose();
    _artistSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    final settingsProv = context.read<UserSettingsProvider>();
    final languagesList = _selectedLanguages.toList();
    final artistsList = _selectedArtists.toList();
    final genresList = _selectedGenres.toList();

    bool success = false;
    if (widget.isEditingMode) {
      success = await settingsProv.updateMusicPreferences(
        languages: languagesList,
        favoriteArtists: artistsList,
        preferredGenres: genresList,
      );
    } else {
      success = await settingsProv.completeOnboarding(
        languages: languagesList,
        favoriteArtists: artistsList,
        preferredGenres: genresList,
      );
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSaving = false;
      });
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else if (widget.isEditingMode) {
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _isSaving = false;
        _saveErrorMessage = 'Could not save preferences to cloud. Tap Retry to try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopProgressBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0
                        ? _buildLanguageSelectionStep()
                        : (_currentStep == 1
                            ? _buildArtistSelectionStep()
                            : _buildGenreSelectionStep()),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
            if (_isSaving) _buildSavingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                )
              else if (widget.isEditingMode)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              else
                const SizedBox(width: 40),
              Text(
                'Step ${_currentStep + 1} of 3',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (_currentStep > 0 && !widget.isEditingMode)
                TextButton(
                  onPressed: () {
                    if (_currentStep == 1) {
                      setState(() => _currentStep = 2);
                    } else {
                      _handleSave();
                    }
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3.0,
              backgroundColor: AppColors.bgSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 1: Language Selection Step
  // ===========================================================================
  Widget _buildLanguageSelectionStep() {
    final filteredLanguages = MusicOnboardingData.availableLanguages.where((l) {
      if (_languageFilter.isEmpty) return true;
      return l.name.toLowerCase().contains(_languageFilter) ||
          l.nativeName.toLowerCase().contains(_languageFilter);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'What languages do you listen to?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick one or more languages to personalize your daily mixes, charts, and recommendations.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _languageSearchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                hintText: 'Search languages (e.g. Bengali, Hindi, English)...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                border: InputBorder.none,
                suffixIcon: _languageFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                        onPressed: () => _languageSearchCtrl.clear(),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Language Cards Grid
          Expanded(
            child: filteredLanguages.isEmpty
                ? Center(
                    child: Text(
                      'No languages found matching "$_languageFilter"',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = filteredLanguages[index];
                      final isSelected = _selectedLanguages.contains(lang.name);
                      return _buildLanguageCard(lang, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(MusicLanguage lang, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedLanguages.remove(lang.name);
          } else {
            _selectedLanguages.add(lang.name);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isSelected
                ? lang.gradient
                : [
                    AppColors.bgSurface,
                    AppColors.bgCard,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: lang.gradient.first.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  lang.icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 24,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang.nativeName,
                      style: TextStyle(
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.black, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 2: Favourite Artists Selection Step
  // ===========================================================================
  Widget _buildArtistSelectionStep() {
    final List<OnboardingArtist> displayedArtists;
    if (_artistFilter.isNotEmpty) {
      displayedArtists = _discoveredArtists;
    } else {
      final relevant = MusicOnboardingData.getArtistsForLanguages(_selectedLanguages.toList());
      if (_activeLanguageFilter == 'All') {
        displayedArtists = relevant;
      } else {
        displayedArtists = relevant.where((a) => a.matchesLanguage(_activeLanguageFilter)).toList();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Choose your favourite artists',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (_selectedArtists.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${_selectedArtists.length} picked',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _selectedLanguages.isNotEmpty
                ? 'Showing top singers & performers in ${_selectedLanguages.join(", ")}'
                : 'Select artists you love to tune your daily mixes and charts.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Artist Search Bar with live search indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _artistSearchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                icon: _isSearchingArtists
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                hintText: 'Search singers, bands, composers (e.g. Arijit Singh)...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                border: InputBorder.none,
                suffixIcon: _artistFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                        onPressed: () => _artistSearchCtrl.clear(),
                      )
                    : null,
              ),
            ),
          ),
          if (_artistFilter.isEmpty && _selectedLanguages.length > 1) ...[
            const SizedBox(height: 12),
            _buildLanguageFilterChips(),
          ],
          const SizedBox(height: 14),
          // Artists Grid (Circular Avatars)
          Expanded(
            child: _isSearchingArtists && displayedArtists.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : displayedArtists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _artistFilter.isNotEmpty
                                  ? 'No artists found matching "$_artistFilter"'
                                  : 'No artists found for selected filter',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: displayedArtists.length,
                        itemBuilder: (context, index) {
                          final artist = displayedArtists[index];
                          final isSelected = _selectedArtists.contains(artist.name);
                          return _buildArtistItem(artist, isSelected);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageFilterChips() {
    final chips = ['All', ..._selectedLanguages];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final lang = chips[index];
          final isActive = _activeLanguageFilter == lang;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeLanguageFilter = lang;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Text(
                  lang,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtistItem(OnboardingArtist artist, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedArtists.remove(artist.name);
          } else {
            _selectedArtists.add(artist.name);
          }
        });
      },
      child: Column(
        children: [
          Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: artist.imageUrl.isNotEmpty
                      ? AppNetworkImage(
                          url: artist.imageUrl,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.person_rounded,
                        )
                      : Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.5),
                                AppColors.bgSurface,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              if (isSelected)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            artist.artistTypeDisplay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            artist.languages.take(2).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3: Moods & Genres Selection Step
  // ===========================================================================
  Widget _buildGenreSelectionStep() {
    final genres = MusicOnboardingData.availableGenres;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'What moods & vibes do you love?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (_selectedGenres.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${_selectedGenres.length} picked',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick moods and styles to tune your daily mixes, workout beats, and chill sessions.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final item = genres[index];
                final isSelected = _selectedGenres.contains(item.name);
                return _buildGenreCard(item, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreCard(MusicGenreMood item, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGenres.remove(item.name);
          } else {
            _selectedGenres.add(item.name);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isSelected
                ? item.gradient
                : [AppColors.bgSurface, AppColors.bgCard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.gradient.first.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 22)),
                    Icon(
                      item.icon,
                      color: isSelected ? Colors.white70 : AppColors.textSecondary.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.black, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM ACTION BAR
  // ===========================================================================
  Widget _buildBottomBar() {
    final bool canProceed = _currentStep == 0
        ? _selectedLanguages.isNotEmpty
        : true; // Step 1 and Step 2 can proceed or be completed

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_saveErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _saveErrorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _handleSave,
                    child: const Text('Retry', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? AppColors.primary : AppColors.bgCard,
                foregroundColor: Colors.white,
                elevation: canProceed ? 6 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: canProceed
                  ? () {
                      if (_currentStep == 0) {
                        setState(() {
                          _currentStep = 1;
                        });
                      } else if (_currentStep == 1) {
                        setState(() {
                          _currentStep = 2;
                        });
                      } else {
                        _handleSave();
                      }
                    }
                  : null,
              child: Text(
                _currentStep == 0
                    ? (_selectedLanguages.isEmpty
                        ? 'Select at least 1 language'
                        : 'Continue to Artists (${_selectedLanguages.length})')
                    : (_currentStep == 1
                        ? (_selectedArtists.isEmpty
                            ? 'Continue to Moods & Vibes'
                            : 'Continue with ${_selectedArtists.length} ${_selectedArtists.length == 1 ? "artist" : "artists"}')
                        : (widget.isEditingMode
                            ? 'Save Preferences'
                            : (_selectedGenres.isEmpty
                                ? 'Finish & Explore Soundifly'
                                : 'Start Listening (${_selectedGenres.length} vibes)'))),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SAVING PROGRESS OVERLAY
  // ===========================================================================
  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Personalizing your Soundifly experience...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Curating mixes and daily recommendations',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
