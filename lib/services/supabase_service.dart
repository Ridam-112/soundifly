import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Diagnostic check result representation
class SupabaseDiagnosticResult {
  final bool isConnected;
  final String message;
  final int? statusCode;

  const SupabaseDiagnosticResult({
    required this.isConnected,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'SupabaseDiagnosticResult(isConnected: $isConnected, message: $message)';
}

/// Central service for Supabase client access and PostgreSQL connection management.
class SupabaseService {
  static bool _isInitialized = false;

  /// Returns true if Supabase has been initialized with valid credentials.
  static bool get isInitialized => _isInitialized;

  /// Get the active SupabaseClient.
  /// Throws a [StateError] if accessed when not yet initialized.
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'SupabaseService has not been initialized. Please configure SUPABASE_ANON_KEY in SupabaseConfig or pass it via --dart-define.',
      );
    }
    return Supabase.instance.client;
  }

  /// Initialize Supabase connection.
  /// Safe to call during app startup (`main()`).
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      developer.log(
        '⚠️ Supabase is not configured yet. Project URL is set to "${SupabaseConfig.url}", but SUPABASE_ANON_KEY is missing. '
        'Set your anon key in lib/config/supabase_config.dart or pass via --dart-define=SUPABASE_ANON_KEY=your_key.',
        name: 'Soundifly.Supabase',
      );
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      _isInitialized = true;
      developer.log(
        '✅ Supabase initialized successfully for project: ${SupabaseConfig.url}',
        name: 'Soundifly.Supabase',
      );
    } catch (e, stack) {
      _isInitialized = false;
      developer.log(
        '❌ Failed to initialize Supabase: $e',
        name: 'Soundifly.Supabase',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Diagnostic verification check for Supabase and PostgreSQL connectivity.
  ///
  /// This executes a lightweight verification against the Supabase backend.
  /// Crucially: If no application tables exist yet, this does NOT treat missing
  /// tables as a connection failure.
  static Future<SupabaseDiagnosticResult> checkConnection() async {
    if (!_isInitialized) {
      return const SupabaseDiagnosticResult(
        isConnected: false,
        message: 'Supabase is not initialized. Please provide your Supabase anon/publishable key.',
      );
    }

    try {
      // 1. Verify Auth service handshake
      await client.auth.getSession();

      // 2. Verify PostgREST / PostgreSQL API connectivity with a lightweight probe
      try {
        await client.from('_connection_probe').select().limit(1);
      } on PostgrestException catch (pgError) {
        // PostgREST errors like PGRST204/PGRST205 or Postgres 42P01 mean the database
        // responded and is reachable, but the test table doesn't exist yet.
        // This is 100% expected during initial project setup!
        if (pgError.code == 'PGRST204' ||
            pgError.code == 'PGRST205' ||
            pgError.code == '42P01' ||
            pgError.code == '404' ||
            pgError.message.contains('relation') ||
            pgError.message.contains('not found') ||
            pgError.message.contains('does not exist')) {
          return const SupabaseDiagnosticResult(
            isConnected: true,
            message: 'Connected to Supabase PostgreSQL successfully! (Backend is online; database tables can be added next).',
          );
        }

        // Invalid API key
        if (pgError.code == '401' || pgError.message.contains('JWT') || pgError.message.contains('apikey')) {
          return SupabaseDiagnosticResult(
            isConnected: false,
            message: 'Authentication failed. Please verify your Supabase anon/publishable key.',
            statusCode: 401,
          );
        }

        // Other PostgREST error where server responded
        return SupabaseDiagnosticResult(
          isConnected: true,
          message: 'Supabase backend responded: ${pgError.message}',
        );
      }

      return const SupabaseDiagnosticResult(
        isConnected: true,
        message: 'Connected to Supabase PostgreSQL successfully!',
      );
    } catch (e) {
      return SupabaseDiagnosticResult(
        isConnected: false,
        message: 'Connection check failed: $e',
      );
    }
  }
}
