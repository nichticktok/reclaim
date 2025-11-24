import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart' show rootBundle;

/// Environment configuration
/// Loads from --dart-define at build time OR from env/.env file at runtime
class AppEnv {
  // Cache for loaded env values
  static Map<String, String>? _envCache;
  // Firebase Emulator Settings
  static const bool useAuthEmulator =
      bool.fromEnvironment('USE_AUTH_EMULATOR', defaultValue: false);
  static const String authEmulatorHost =
      String.fromEnvironment('AUTH_EMULATOR_HOST', defaultValue: '');
  static const int authEmulatorPort =
      int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099);

  static const bool useFirestoreEmulator =
      bool.fromEnvironment('USE_FIRESTORE_EMULATOR', defaultValue: false);
  static const String firestoreEmulatorHost =
      String.fromEnvironment('FIRESTORE_EMULATOR_HOST', defaultValue: '');
  static const int firestoreEmulatorPort =
      int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080);

  // Functions Emulator Settings
  static const bool useFunctionsEmulator =
      bool.fromEnvironment('USE_FUNCTIONS_EMULATOR', defaultValue: false);
  static const String functionsRegion =
      String.fromEnvironment('FUNCTIONS_REGION', defaultValue: 'us-central1');
  static const String functionsEmulatorHost =
      String.fromEnvironment('FUNCTIONS_EMULATOR_HOST', defaultValue: '');
  static const int functionsEmulatorPort =
      int.fromEnvironment('FUNCTIONS_EMULATOR_PORT', defaultValue: 5001);

  // App Info
  static const String appName = 'Reclaim';
  static const String appVersion = '1.0.0';

  // Environment
  static const String environment =
      String.fromEnvironment('ENV', defaultValue: 'dev');
  
  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';
  static bool get isQa => environment == 'qa';

  // AI Configuration
  static String get geminiApiKey {
    // First try --dart-define (build-time)
    final fromDefine = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    
    // Then try loading from cache (if already loaded)
    return _loadEnvFileSync()['GEMINI_API_KEY'] ?? '';
  }

  /// Initialize and load environment variables (call this early in main)
  static Future<void> initialize() async {
    await _loadEnvFile();
  }

  /// Load environment variables from assets or env/.env file
  static Future<Map<String, String>> _loadEnvFile() async {
    // Return cache if already loaded
    if (_envCache != null) {
      return _envCache!;
    }

    _envCache = <String, String>{};

    // First, try loading from assets (works on all platforms)
    try {
      final envContent = await rootBundle.loadString('assets/.env');
      _parseEnvFileContent(envContent);
      final keyLoaded = _envCache!['GEMINI_API_KEY']?.isNotEmpty ?? false;
      if (keyLoaded) {
        debugPrint('[AppEnv] ✅ Loaded GEMINI_API_KEY from assets/.env');
        return _envCache!;
      }
    } catch (e) {
      debugPrint('[AppEnv] Could not load from assets: $e');
    }

    // Fallback: Try loading from file system (for local development)
    if (!kIsWeb) {
      try {
        final currentDir = Directory.current.path;
        final possiblePaths = [
          'env/.env',
          '.env',
          '../env/.env',
          '../../env/.env',
          '$currentDir/env/.env',
          '$currentDir/.env',
        ];
        
        File? foundFile;
        for (final path in possiblePaths) {
          final file = File(path);
          if (file.existsSync()) {
            foundFile = file;
            break;
          }
        }
        
        if (foundFile != null) {
          _parseEnvFile(foundFile);
          final keyLoaded = _envCache!['GEMINI_API_KEY']?.isNotEmpty ?? false;
          if (keyLoaded) {
            debugPrint('[AppEnv] ✅ Loaded GEMINI_API_KEY from ${foundFile.path}');
          }
        }
      } catch (e) {
        debugPrint('[AppEnv] Could not load from file system: $e');
      }
    }

    if (_envCache!['GEMINI_API_KEY']?.isEmpty ?? true) {
      debugPrint('[AppEnv] ⚠️ GEMINI_API_KEY not found. Make sure env/.env exists in assets or use --dart-define');
    }

    return _envCache!;
  }

  /// Synchronous version for getter (loads from cache or returns empty)
  static Map<String, String> _loadEnvFileSync() {
    return _envCache ?? <String, String>{};
  }

  /// Parse .env file content from File
  static void _parseEnvFile(File file) {
    final content = file.readAsStringSync();
    _parseEnvFileContent(content);
  }

  /// Parse .env file content from string
  static void _parseEnvFileContent(String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }
      
      // Parse KEY=VALUE format
      final equalsIndex = line.indexOf('=');
      if (equalsIndex > 0) {
        final key = line.substring(0, equalsIndex).trim();
        final value = line.substring(equalsIndex + 1).trim();
        // Remove quotes if present
        String cleanValue = value;
        if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
          cleanValue = cleanValue.substring(1, cleanValue.length - 1);
        } else if (cleanValue.startsWith("'") && cleanValue.endsWith("'")) {
          cleanValue = cleanValue.substring(1, cleanValue.length - 1);
        }
        _envCache![key] = cleanValue;
      }
    }
  }
}

