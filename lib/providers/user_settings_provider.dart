import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/supabase_service.dart';
import '../services/supabase_user_service.dart';

class UserSettingsProvider extends ChangeNotifier {
  UserSettings _settings = const UserSettings(userId: 'guest');
  bool _isLoading = false;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;

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
    loadSettings();
  }

  Future<void> loadSettings() async {
    if (!SupabaseService.isInitialized) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final remote = await SupabaseUserService.fetchSettings(user.id);
      if (remote != null) {
        _settings = remote;
      } else {
        _settings = UserSettings.defaults(userId: user.id);
        await SupabaseUserService.saveSettings(_settings);
      }
    } catch (e) {
      debugPrint('Note: Settings load skipped: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
