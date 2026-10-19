/// Configuration constants for Supabase connectivity in Soundifly.
///
/// These values can be injected at build-time using `--dart-define`:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// IMPORTANT SECURITY NOTICE:
/// - Only use the `publishable` client key in client apps.
/// - Direct PostgreSQL database connection strings and passwords must NEVER
///   be placed in client-side Flutter code. Client access is mediated via
///   Supabase APIs and PostgreSQL Row Level Security (RLS).
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://riolkjnhvrpyknlqcikr.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_aCfUzEAgivngEPf2RvuZbQ_PJfnsEma',
  );

  /// Backwards-compatible alias
  static String get anonKey => publishableKey;

  /// Helper to check if credentials have been populated
  static bool get isConfigured =>
      url.isNotEmpty &&
      publishableKey.isNotEmpty &&
      publishableKey != 'your_supabase_anon_publishable_key_here';
}
