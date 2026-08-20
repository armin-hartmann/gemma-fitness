import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _geminiApiKeyPref = 'gemini_api_key';

  /// Returns the API key from compile-time environment OR local persistent storage.
  Future<String?> getGeminiApiKey() async {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    final localKey = prefs.getString(_geminiApiKeyPref);
    if (localKey != null && localKey.trim().isNotEmpty) {
      return localKey.trim();
    }

    return null;
  }

  /// Persists API key securely in browser localStorage or device preferences.
  Future<void> saveGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyPref, apiKey.trim());
  }

  /// Clears persisted API key.
  Future<void> clearGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiApiKeyPref);
  }

  /// Checks if compile-time environment variable is set.
  bool get hasEnvironmentKey {
    return const String.fromEnvironment('GEMINI_API_KEY').trim().isNotEmpty;
  }
}
