import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../services/supabase_service.dart';
import '../services/supabase_user_service.dart';

class UserSettingsProvider extends ChangeNotifier {
  UserSettings _settings = const UserSettings(userId: 'guest');
  bool _isLoading = false;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get onboardingCompleted => _settings.onboardingCompleted;
  List<String> get preferredLanguages => _settings.preferredLanguages;
  List<String> get favoriteArtists => _settings.favoriteArtists;
  List<String> get preferredGenres => _settings.preferredGenres;

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  UserSettingsProvider() {
    _restoreLocalPreferences();
    loadSettings();
  }

  /// Instant local cache restoration to avoid UI flicker on launch
  Future<void> _restoreLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;
      final effectiveUid = user?.id ?? 'guest';

      final cachedCompleted = prefs.getBool('soundifly_onboarding_completed_$effectiveUid');
      final cachedLangs = prefs.getStringList('soundifly_languages_$effectiveUid');
      final cachedArtists = prefs.getStringList('soundifly_artists_$effectiveUid');
      final cachedGenres = prefs.getStringList('soundifly_genres_$effectiveUid');

      if (cachedCompleted != null) {
        _settings = _settings.copyWith(
          onboardingCompleted: cachedCompleted,
          preferredLanguages: cachedLangs ?? _settings.preferredLanguages,
          favoriteArtists: cachedArtists ?? _settings.favoriteArtists,
          preferredGenres: cachedGenres ?? _settings.preferredGenres,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('SharedPreferences restore note: $e');
    }
  }

  Future<void> loadSettings() async {
    if (!SupabaseService.isInitialized) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Check local fast-cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedCompleted = prefs.getBool('soundifly_onboarding_completed_${user.id}');
      final cachedLangs = prefs.getStringList('soundifly_languages_${user.id}');
      final cachedArtists = prefs.getStringList('soundifly_artists_${user.id}');
      final cachedGenres = prefs.getStringList('soundifly_genres_${user.id}');

      // 2. Fetch authoritative remote settings from Supabase
      final remote = await SupabaseUserService.fetchSettings(user.id);
      if (remote != null) {
        // If local had onboarding completed and remote was pending, prioritize completion
        final isCompleted = remote.onboardingCompleted || (cachedCompleted ?? false);
        final langs = remote.preferredLanguages.isNotEmpty
            ? remote.preferredLanguages
            : (cachedLangs ?? const []);
        final artists = remote.favoriteArtists.isNotEmpty
            ? remote.favoriteArtists
            : (cachedArtists ?? const []);
        final genres = remote.preferredGenres.isNotEmpty
            ? remote.preferredGenres
            : (cachedGenres ?? const []);

        _settings = remote.copyWith(
          onboardingCompleted: isCompleted,
          preferredLanguages: langs,
          favoriteArtists: artists,
          preferredGenres: genres,
        );

        // Update local cache
        await prefs.setBool('soundifly_onboarding_completed_${user.id}', isCompleted);
        await prefs.setStringList('soundifly_languages_${user.id}', langs);
        await prefs.setStringList('soundifly_artists_${user.id}', artists);
        await prefs.setStringList('soundifly_genres_${user.id}', genres);
      } else {
        _settings = UserSettings.defaults(userId: user.id).copyWith(
          onboardingCompleted: cachedCompleted ?? false,
          preferredLanguages: cachedLangs ?? const [],
          favoriteArtists: cachedArtists ?? const [],
          preferredGenres: cachedGenres ?? const [],
        );
        await SupabaseUserService.saveSettings(_settings);
      }
    } catch (e) {
      debugPrint('Note: Settings load skipped: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark onboarding as completed with preferred languages, artists, and genres
  Future<bool> completeOnboarding({
    required List<String> languages,
    required List<String> favoriteArtists,
    List<String> preferredGenres = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;
      final effectiveUid = user?.id ?? 'guest';

      _settings = _settings.copyWith(
        onboardingCompleted: true,
        preferredLanguages: languages,
        favoriteArtists: favoriteArtists,
        preferredGenres: preferredGenres,
      );

      // Save to local device storage immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('soundifly_onboarding_completed_$effectiveUid', true);
      await prefs.setStringList('soundifly_languages_$effectiveUid', languages);
      await prefs.setStringList('soundifly_artists_$effectiveUid', favoriteArtists);
      await prefs.setStringList('soundifly_genres_$effectiveUid', preferredGenres);

      // Save to Supabase cloud if authenticated
      if (user != null) {
        final saved = await SupabaseUserService.saveSettings(_settings);
        if (!saved) {
          debugPrint('⚠️ Warning: Cloud sync for onboarding failed, saved locally.');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error saving onboarding: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update music preferences from Profile/Settings screen
  Future<bool> updateMusicPreferences({
    List<String>? languages,
    List<String>? favoriteArtists,
    List<String>? preferredGenres,
  }) async {
    _settings = _settings.copyWith(
      preferredLanguages: languages ?? _settings.preferredLanguages,
      favoriteArtists: favoriteArtists ?? _settings.favoriteArtists,
      preferredGenres: preferredGenres ?? _settings.preferredGenres,
    );
    notifyListeners();

    try {
      final user = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;
      final effectiveUid = user?.id ?? 'guest';

      final prefs = await SharedPreferences.getInstance();
      if (languages != null) {
        await prefs.setStringList('soundifly_languages_$effectiveUid', languages);
      }
      if (favoriteArtists != null) {
        await prefs.setStringList('soundifly_artists_$effectiveUid', favoriteArtists);
      }
      if (preferredGenres != null) {
        await prefs.setStringList('soundifly_genres_$effectiveUid', preferredGenres);
      }

      await _persist();
      return true;
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      return false;
    }
  }

  /// Check whether an artist is followed/favorited
  bool isArtistFollowed(String artistName) {
    final lower = artistName.trim().toLowerCase();
    return _settings.favoriteArtists.any((a) => a.toLowerCase() == lower);
  }

  /// Toggle follow/favourite status for an artist
  Future<void> toggleFollowArtist(String artistName) async {
    final trimmed = artistName.trim();
    if (trimmed.isEmpty) return;

    final list = List<String>.from(_settings.favoriteArtists);
    final idx = list.indexWhere((a) => a.toLowerCase() == trimmed.toLowerCase());
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(trimmed);
    }

    await updateMusicPreferences(favoriteArtists: list);
  }

  Future<void> updateThemeMode(String mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _persist();
  }

  Future<void> updateAudioQuality(String quality) async {
    _settings = _settings.copyWith(audioQuality: quality);
    notifyListeners();
    await _persist();
  }

  Future<void> updateAutoplay(bool autoplay) async {
    _settings = _settings.copyWith(autoplay: autoplay);
    notifyListeners();
    await _persist();
  }

  Future<void> updateKeepHistory(bool keepHistory) async {
    _settings = _settings.copyWith(keepHistory: keepHistory);
    notifyListeners();
    await _persist();
  }

  Future<void> updateLiveLyricsEnabled(bool val) async {
    _settings = _settings.copyWith(liveLyricsEnabled: val);
    notifyListeners();
    await _persist();
  }

  Future<void> updateMiniPlayerLyricsEnabled(bool val) async {
    _settings = _settings.copyWith(miniPlayerLyricsEnabled: val);
    notifyListeners();
    await _persist();
  }

  Future<void> updateNotificationLyricsEnabled(bool val) async {
    _settings = _settings.copyWith(notificationLyricsEnabled: val);
    notifyListeners();
    await _persist();
  }

  Future<void> updateMiniPlayerInitialModeLyrics(bool val) async {
    _settings = _settings.copyWith(miniPlayerInitialModeLyrics: val);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    if (!SupabaseService.isInitialized) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    await SupabaseUserService.saveSettings(_settings.copyWith());
  }
}
