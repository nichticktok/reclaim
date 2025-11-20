/// Environment configuration
/// Use --dart-define to set values at build time
class AppEnv {
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
}

