import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LangOption {
  final String id;     // stable id, e.g. "18_24"
  final String label;  // localized label
  const LangOption({required this.id, required this.label});
}

class LanguageProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Locale _locale = const Locale('en'); // Default to English
  bool _isLoading = false;
  
  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('ne'), // Nepali
  ];
  
  // Map locale codes to display names
  static String getLanguageDisplayName(String localeCode) {
    switch (localeCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'ne':
        return 'नेपाली';
      default:
        return localeCode;
    }
  }
  
  /// Initialize language from Firebase or use device locale
  Future<void> initialize() async {
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      Locale? savedLocale;
      
      if (user != null) {
        // Try to load from user settings
        final settingsDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('preferences')
            .get();
        
        if (settingsDoc.exists) {
          final data = settingsDoc.data();
          final savedLangCode = data?['language'] as String?;
          if (savedLangCode != null) {
            savedLocale = Locale(savedLangCode);
            if (supportedLocales.contains(savedLocale)) {
              _locale = savedLocale;
              // Language preference loaded
              notifyListeners();
              _isLoading = false;
              return;
            }
          }
        }
      }
      
      // If no saved preference, use device locale
      final deviceLocale = PlatformDispatcher.instance.locale;
      final deviceLanguageCode = deviceLocale.languageCode;
      
      // Map device locale to supported locale
      Locale? matchedLocale;
      for (final supported in supportedLocales) {
        if (supported.languageCode == deviceLanguageCode) {
          matchedLocale = supported;
          break;
        }
      }
      
      // Default to English if device locale not supported
      _locale = matchedLocale ?? const Locale('en');
      // Using device locale
      
      // Save device locale preference if user is logged in
      if (user != null && matchedLocale != null) {
        await _saveLanguagePreference(user.uid, matchedLocale.languageCode);
      }
    } catch (e) {
      // Error loading language preference
      _locale = const Locale('en'); // Fallback to English
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set language and persist to Firebase
  Future<void> setLanguage(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) {
      // Unsupported locale
      return;
    }
    
    if (_locale.languageCode == newLocale.languageCode) return;
    
    _locale = newLocale;
    notifyListeners();
    
    // Persist to Firebase
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveLanguagePreference(user.uid, newLocale.languageCode);
        // Language saved to Firebase
      }
    } catch (e) {
      // Error saving language preference
    }
  }
  
  /// Helper to save language preference
  Future<void> _saveLanguagePreference(String userId, String languageCode) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .set({
      'language': languageCode,
      'languageUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  /// Get locale from language code string
  Locale getLocaleFromCode(String code) {
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => const Locale('en'),
    );
  }
  
  /// Set language from language code string
  Future<void> setLanguageFromCode(String code) async {
    await setLanguage(getLocaleFromCode(code));
  }
}
