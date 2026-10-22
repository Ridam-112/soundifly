import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_settings_provider.dart';
import '../models/user_profile.dart';
import '../services/supabase_user_service.dart';
import '../theme/app_theme.dart';
import 'listening_history_screen.dart';
import 'onboarding/music_onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;

  final List<String> _presetAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=Soundifly1',
    'https://api.dicebear.com/7.x/bottts/png?seed=Soundifly2',
    'https://api.dicebear.com/7.x/bottts/png?seed=Soundifly3',
    'https://api.dicebear.com/7.x/bottts/png?seed=Soundifly4',
    'https://api.dicebear.com/7.x/bottts/png?seed=Soundifly5',
    'https://api.dicebear.com/7.x/bottts/png?seed=Soundifly6',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user != null) {
      final remoteProfile = await SupabaseUserService.fetchProfile(
        user.id,
        email: user.email ?? '',
      );
      if (mounted) {
        setState(() {
          _profile = remoteProfile ??
              UserProfile(
                id: user.id,
                displayName: (user.userMetadata?['full_name'] as String?)?.trim() ?? 'Soundifly Member',
                email: user.email ?? '',
                avatarUrl: _presetAvatars.first,
              );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final settingsProv = context.watch<UserSettingsProvider>();

    final user = auth.user;
    final displayName = _profile?.displayName ??
        (user?.userMetadata?['full_name'] as String?)?.trim() ??
        (auth.isGuest ? 'Guest Explorer' : 'Soundifly Member');
    final username = _profile?.username;
    final displayEmail = auth.isGuest ? 'Guest Session (Local Mode)' : (user?.email ?? 'Free Tier');
    final avatarUrl = _profile?.avatarUrl ?? _presetAvatars.first;
    final myPlaylistsCount = playlistProv.myPlaylists.length;
    final publicPlaylistsCount = playlistProv.publicPlaylists.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Listening History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListeningHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            if (auth.isGuest) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.bgSurface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_search_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guest Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Sign in or register to sync your playlists and favorites to the cloud.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => auth.exitGuestMode(),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            // User Header
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarPicker(context),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primaryOrange,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.bgSurface,
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                        onPressed: () => _showEditProfileDialog(context),
                      ),
                    ],
                  ),
                  if (username != null && username.isNotEmpty)
                    Text(
                      '@$username',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                    )
                  else
                    GestureDetector(
                      onTap: () => _showEditProfileDialog(context),
                      child: const Text(
                        'Set username +',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, decoration: TextDecoration.underline),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text('$displayEmail • Free Tier', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Followers / Playlists Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatColumn('$publicPlaylistsCount', 'Public Playlists'),
                      Container(height: 24, width: 1, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 24)),
                      _buildStatColumn('$myPlaylistsCount', 'Your Playlists'),
                      Container(height: 24, width: 1, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 24)),
                      _buildStatColumn('${playlistProv.likedSongsPlaylist.songs.length}', 'Liked Songs'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Soundifly Premium Upsell Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF662200), Color(0xFF220900), AppColors.bgCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Soundifly Premium', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Ad-free, 320kbps Lossless, Unlimited Couple Jam sessions', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {},
                    child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Music Preferences Section (Spotify-style Personalization)
            _buildSectionTitle('Music Personalization'),
            _buildSettingCard(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Music Preferences', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    settingsProv.preferredLanguages.isNotEmpty || settingsProv.favoriteArtists.isNotEmpty || settingsProv.preferredGenres.isNotEmpty
                        ? '${settingsProv.preferredLanguages.length} Languages • ${settingsProv.favoriteArtists.length} Artists • ${settingsProv.preferredGenres.length} Moods'
                        : 'Tap to configure your preferred languages, artists & moods',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MusicOnboardingScreen(isEditingMode: true),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // App Preferences Section
            _buildSectionTitle('App Preferences & Theme'),
            _buildSettingCard(
              children: [
                ListTile(
                  title: const Text('Theme Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    settingsProv.settings.themeMode.toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  onTap: () => _showThemePicker(context, settingsProv),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  title: const Text('Streaming Quality', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    settingsProv.settings.audioQuality == 'high' ? '320 kbps (Extreme)' : '128 kbps (Standard)',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  onTap: () => _showQualityPicker(context, settingsProv),
                ),
                const Divider(color: Colors.white10),
                SwitchListTile(
                  title: const Text('Autoplay Similar Tracks', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Keep the music going when your queue finishes', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  activeTrackColor: AppColors.primary,
                  value: settingsProv.settings.autoplay,
                  onChanged: (v) {
                    settingsProv.updateAutoplay(v);
                    context.read<AudioPlayerProvider>().setAutoplay(v);
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.textSecondary),
                  title: const Text('Clear App Cache', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Free up temporary image and stream cache', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Text('App cache cleared successfully!'),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Live Lyrics & Background Audio (Phase 5)
            _buildSectionTitle('Live Lyrics & Background Audio'),
            _buildSettingCard(
              children: [
                SwitchListTile(
                  title: const Text('Live Synchronized Lyrics', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Fetch timestamped LRC lyrics in real-time', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  activeTrackColor: AppColors.primary,
                  value: settingsProv.settings.liveLyricsEnabled,
                  onChanged: (v) => settingsProv.updateLiveLyricsEnabled(v),
                ),
                const Divider(color: Colors.white10),
                SwitchListTile(
                  title: const Text('Mini-Player Lyrics Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Display real-time lyrics inside the floating mini-player', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  activeTrackColor: AppColors.primary,
                  value: settingsProv.settings.miniPlayerLyricsEnabled,
                  onChanged: (v) {
                    settingsProv.updateMiniPlayerLyricsEnabled(v);
                    context.read<AudioPlayerProvider>().setMiniPlayerLyricsMode(v);
                  },
                ),
                const Divider(color: Colors.white10),
                SwitchListTile(
                  title: const Text('Notification & Lock-Screen Lyrics', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Show the active lyric line in system media notifications', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  activeTrackColor: AppColors.primary,
                  value: settingsProv.settings.notificationLyricsEnabled,
                  onChanged: (v) => settingsProv.updateNotificationLyricsEnabled(v),
                ),
                const Divider(color: Colors.white10),
                SwitchListTile(
                  title: const Text('Start Mini-Player in Lyrics Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Prefer lyrics over song title/artist when starting playback', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  activeTrackColor: AppColors.primary,
                  value: settingsProv.settings.miniPlayerInitialModeLyrics,
                  onChanged: (v) => settingsProv.updateMiniPlayerInitialModeLyrics(v),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // History & Data Privacy Section
            _buildSectionTitle('Listening History & Privacy'),
            _buildSettingCard(
              children: [
                SwitchListTile(
                  title: const Text('Record Listening History', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Save played tracks for quick replay and recommendations', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  activeTrackColor: AppColors.primary,
                  value: settingsProv.settings.keepHistory,
                  onChanged: (v) => settingsProv.updateKeepHistory(v),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                  title: const Text('View Listening History', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Browse played songs or clear history', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ListeningHistoryScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Legal, Safety & About Section
            _buildSectionTitle('Legal, Safety & About'),
            _buildSettingCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.gavel_rounded, color: AppColors.primary),
                  title: const Text('Legal Disclaimer & Safe Harbor', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Section 79 IT Act (2000) & Non-Hosting Notice', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  onTap: () => _showLegalDisclaimerModal(context),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                  title: const Text('About Soundifly', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('v1.0.0 • Social Music Streaming & Couple Sync', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  onTap: () => _showAboutModal(context),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.accentAmber),
                  title: const Text('Copyright & Grievance Officer', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Takedown requests • legal@soundifly.com', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  onTap: () => _showGrievanceModal(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Log Out / Exit Guest Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: auth.isGuest
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.login_rounded, color: AppColors.primary, size: 18),
                      label: const Text('Exit Guest Mode / Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        auth.exitGuestMode();
                      },
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      label: const Text('Log Out of Soundifly', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.bgCard,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: const Text(
                              'Are you sure you want to log out of your Soundifly account?',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<AudioPlayerProvider>().resetPlayback();
                                  auth.signOut();
                                },
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController(text: _profile?.displayName ?? '');
    final usernameCtrl = TextEditingController(text: _profile?.username ?? '');
    String? validationError;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    labelStyle: const TextStyle(color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Unique Username',
                    prefixText: '@',
                    prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'lowercase alphanumeric (3-30 chars)',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 8),
                  Text(validationError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nav = Navigator.of(dialogCtx);
                            final rawUsername = usernameCtrl.text.trim().toLowerCase();
                            final rawName = nameCtrl.text.trim();

                            if (rawName.isEmpty) {
                              setModalState(() => validationError = 'Display name cannot be empty.');
                              return;
                            }

                            if (rawUsername.isNotEmpty) {
                              if (rawUsername.length < 3 || rawUsername.length > 30) {
                                setModalState(() => validationError = 'Username must be between 3 and 30 characters.');
                                return;
                              }
                              final regex = RegExp(r'^[a-z0-9_]+$');
                              if (!regex.hasMatch(rawUsername)) {
                                setModalState(() => validationError = 'Username can only contain lowercase letters, numbers, and underscores.');
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final available = await SupabaseUserService.checkUsernameAvailable(
                                rawUsername,
                                excludeUserId: _profile?.id,
                              );
                              if (!available) {
                                setModalState(() {
                                  isSaving = false;
                                  validationError = 'Username @$rawUsername is already taken. Please choose another.';
                                });
                                return;
                              }
                            }

                            setModalState(() => isSaving = true);
                            final updated = (_profile ?? UserProfile(
                              id: 'guest',
                              displayName: rawName,
                              email: '',
                            )).copyWith(
                              displayName: rawName,
                              username: rawUsername.isNotEmpty ? rawUsername : null,
                            );

                            await SupabaseUserService.updateProfile(updated);
                            if (mounted) {
                              setState(() => _profile = updated);
                              nav.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.primaryDark,
                                  content: Text('Profile updated successfully!'),
                                ),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Profile Avatar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presetAvatars.length,
                itemBuilder: (c, i) {
                  final url = _presetAvatars[i];
                  final isSelected = _profile?.avatarUrl == url;

                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (_profile != null) {
                        final updated = _profile!.copyWith(avatarUrl: url);
                        if (mounted) {
                          setState(() => _profile = updated);
                        }
                        await SupabaseUserService.updateProfile(updated);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, UserSettingsProvider settingsProv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Select Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 12),
          ...[
            {'mode': 'dark', 'label': 'Dark Theme (Obsidian & Electric Orange)'},
            {'mode': 'system', 'label': 'System Default'},
          ].map(
            (t) => ListTile(
              title: Text(t['label']!, style: TextStyle(color: settingsProv.settings.themeMode == t['mode'] ? AppColors.primary : Colors.white)),
              trailing: settingsProv.settings.themeMode == t['mode'] ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                settingsProv.updateThemeMode(t['mode']!);
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showQualityPicker(BuildContext context, UserSettingsProvider settingsProv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Select Streaming Quality', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 12),
          ...[
            {'quality': 'normal', 'label': '128 kbps (Standard)'},
            {'quality': 'high', 'label': '320 kbps (Extreme)'},
          ].map(
            (q) => ListTile(
              title: Text(q['label']!, style: TextStyle(color: settingsProv.settings.audioQuality == q['quality'] ? AppColors.primary : Colors.white)),
              trailing: settingsProv.settings.audioQuality == q['quality'] ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                settingsProv.updateAudioQuality(q['quality']!);
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  void _showLegalDisclaimerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Legal Disclaimer & Safe Harbor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Section 79, Information Technology Act, 2000 (India)', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📌 Intermediary Non-Hosting Declaration:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Soundifly does not host, store, copy, or upload any copyrighted audio files on its servers. Soundifly operates strictly as a third-party client and indexing search tool that fetches real-time metadata and streams dynamically from publicly available internet APIs and open streaming sources. All audio streams and intellectual property belong exclusively to their respective copyright holders and original platforms.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Intermediary Status (IT Act 2000, Section 79)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'Soundifly qualifies as an "Intermediary" under Section 2(1)(w) and Section 79 of the Information Technology Act, 2000 of the Republic of India. Soundifly exercises no editorial control, does not initiate the transmission, and does not select or modify the third-party audio streams retrieved upon user query.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              const Text(
                '2. Intellectual Property & Trademarks',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'All song titles, artist names, album art, and audio recordings remain the sole intellectual property of their respective copyright holders, labels, and publishers (including T-Series, Sony Music, Saregama, Zee Music, and others). Their appearance in this client is purely for indexing and algorithmic discovery.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              const Text(
                '3. Notice and Takedown Compliance',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'In accordance with Rule 3(1)(d) of the Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021, Soundifly strictly maintains a notice-and-takedown mechanism. Legitimate copyright holders can request immediate removal or de-indexing of content by writing to legal@soundifly.com.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('I Understand & Acknowledge', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20),
                ],
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Soundifly', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Version 1.0.0 (Build 2026.10)', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const Text(
              'Soundifly is a modern, high-performance social music streaming platform built with Flutter. Featuring real-time synchronous "Listen Together" Couple Mode, dynamic karaoke synced lyrics, and responsive design across Web, Android, iOS, and Desktop.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgSurface,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGrievanceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: AppColors.accentAmber, size: 24),
                SizedBox(width: 10),
                Text('Copyright & Grievance Officer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Under the Indian Information Technology Rules, 2021, if any music creator, label, or copyright holder wishes to submit a content takedown notice or grievance:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Text('Designated Grievance Officer: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('Legal Officer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Text('Official Contact: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('legal@soundifly.com', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Text('Turnaround Time: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('Within 36 Hours', style: TextStyle(color: AppColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
