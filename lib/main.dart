import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/audio_player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/listening_room_provider.dart';
import 'providers/user_settings_provider.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend connection safely
  await SupabaseService.initialize();

  if (kDebugMode && SupabaseService.isInitialized) {
    SupabaseService.checkConnection().then((diag) {
      debugPrint('⚡ [Supabase Health] ${diag.message}');
    });
  }

  runApp(const SoundiflyApp());
}

class SoundiflyApp extends StatelessWidget {
  const SoundiflyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => UserSettingsProvider()),
        ChangeNotifierProxyProvider<AudioPlayerProvider, ListeningRoomProvider>(
          create: (_) => ListeningRoomProvider(),
          update: (_, audioPlayer, roomProv) {
            final prov = roomProv ?? ListeningRoomProvider();
            prov.attachAudioPlayer(audioPlayer);
            return prov;
          },
        ),
      ],
      child: Consumer<UserSettingsProvider>(
        builder: (context, settingsProv, _) {
          return MaterialApp(
            title: 'Soundifly - Real-time Music & Social Listening',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            themeMode: settingsProv.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
