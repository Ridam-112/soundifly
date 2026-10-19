import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_settings_provider.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../theme/app_theme.dart';
import 'responsive_scaffold.dart';

/// Central authentication routing gate with session state synchronization.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastLoadedUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Initial session restoration check (prevents screen flicker)
    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Password reset callback flow
    if (auth.needsPasswordReset) {
      return const ResetPasswordScreen();
    }

    // Authenticated application or Guest session
    if (auth.isAuthenticated || auth.isGuest) {
      final currentUserId = auth.user?.id;
      if (currentUserId != null && currentUserId != _lastLoadedUserId) {
        _lastLoadedUserId = currentUserId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<PlaylistProvider>().refreshFromCloud();
            context.read<UserSettingsProvider>().loadSettings();
          }
        });
      }
      return const ResponsiveScaffold();
    }

    // Reset session marker when signed out
    _lastLoadedUserId = null;

    // Unauthenticated entry
    return const AuthScreen();
  }
}
