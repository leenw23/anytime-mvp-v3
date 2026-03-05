class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://wdozrhjtmflwgodzqkiy.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indkb3pyaGp0bWZsd2dvZHpxa2l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNTMxMDcsImV4cCI6MjA4NjgyOTEwN30.w91J3CG_BXJsKzK20yVU-CPy5AcGnnrU8fzE_JwavD0';

  static String get chatFunctionUrl => '$url/functions/v1/chat';
  static String get routineFunctionUrl => '$url/functions/v1/companion-routine';
  static String get extractProfileUrl => '$url/functions/v1/extract-profile';
}
