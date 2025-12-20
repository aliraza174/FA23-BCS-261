import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get openAiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<void> initialize() async {
    await dotenv.load();
  }

  static bool get isValid {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        openAiKey.isNotEmpty;
  }
}
