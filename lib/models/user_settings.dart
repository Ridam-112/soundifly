class UserSettings {
  final String userId;
  final String themeMode; // 'dark', 'light', 'system'
  final String audioQuality; // 'normal', 'high', 'lossless'
  final bool autoplay;
  final bool keepHistory;
  final bool liveLyricsEnabled;
  final bool miniPlayerLyricsEnabled;
  final bool notificationLyricsEnabled;
  final bool miniPlayerInitialModeLyrics;
  final bool onboardingCompleted;
  final List<String> preferredLanguages;
  final List<String> favoriteArtists;
  final List<String> preferredGenres;
  final DateTime? updatedAt;

  const UserSettings({
    required this.userId,
    this.themeMode = 'dark',
    this.audioQuality = 'high',
    this.autoplay = true,
    this.keepHistory = true,
    this.liveLyricsEnabled = true,
    this.miniPlayerLyricsEnabled = false,
    this.notificationLyricsEnabled = true,
    this.miniPlayerInitialModeLyrics = false,
    this.onboardingCompleted = false,
    this.preferredLanguages = const [],
    this.favoriteArtists = const [],
    this.preferredGenres = const [],
    this.updatedAt,
  });

  factory UserSettings.defaults({required String userId}) {
    return UserSettings(userId: userId);
  }

  factory UserSettings.fromMap(Map<String, dynamic> map, {required String userId}) {
    return UserSettings(
      userId: map['user_id']?.toString() ?? userId,
      themeMode: map['theme_mode']?.toString() ?? 'dark',
      audioQuality: map['audio_quality']?.toString() ?? 'high',
      autoplay: map['autoplay'] as bool? ?? true,
      keepHistory: map['keep_history'] as bool? ?? true,
      liveLyricsEnabled: map['live_lyrics_enabled'] as bool? ?? true,
      miniPlayerLyricsEnabled: map['mini_player_lyrics_enabled'] as bool? ?? false,
      notificationLyricsEnabled: map['notification_lyrics_enabled'] as bool? ?? true,
      miniPlayerInitialModeLyrics: map['mini_player_initial_mode_lyrics'] as bool? ?? false,
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
      preferredLanguages: (map['preferred_languages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      favoriteArtists: (map['favorite_artists'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      preferredGenres: (map['preferred_genres'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'theme_mode': themeMode,
      'audio_quality': audioQuality,
      'autoplay': autoplay,
      'keep_history': keepHistory,
      'live_lyrics_enabled': liveLyricsEnabled,
      'mini_player_lyrics_enabled': miniPlayerLyricsEnabled,
      'notification_lyrics_enabled': notificationLyricsEnabled,
      'mini_player_initial_mode_lyrics': miniPlayerInitialModeLyrics,
      'onboarding_completed': onboardingCompleted,
      'preferred_languages': preferredLanguages,
      'favorite_artists': favoriteArtists,
      'preferred_genres': preferredGenres,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? themeMode,
    String? audioQuality,
    bool? autoplay,
    bool? keepHistory,
    bool? liveLyricsEnabled,
    bool? miniPlayerLyricsEnabled,
    bool? notificationLyricsEnabled,
    bool? miniPlayerInitialModeLyrics,
    bool? onboardingCompleted,
    List<String>? preferredLanguages,
    List<String>? favoriteArtists,
    List<String>? preferredGenres,
  }) {
    return UserSettings(
      userId: userId,
      themeMode: themeMode ?? this.themeMode,
      audioQuality: audioQuality ?? this.audioQuality,
      autoplay: autoplay ?? this.autoplay,
      keepHistory: keepHistory ?? this.keepHistory,
      liveLyricsEnabled: liveLyricsEnabled ?? this.liveLyricsEnabled,
      miniPlayerLyricsEnabled: miniPlayerLyricsEnabled ?? this.miniPlayerLyricsEnabled,
      notificationLyricsEnabled: notificationLyricsEnabled ?? this.notificationLyricsEnabled,
      miniPlayerInitialModeLyrics: miniPlayerInitialModeLyrics ?? this.miniPlayerInitialModeLyrics,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      favoriteArtists: favoriteArtists ?? this.favoriteArtists,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      updatedAt: DateTime.now(),
    );
  }
}
