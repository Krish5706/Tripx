import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  final SharedPreferences _prefs;
  String _selectedLanguage;

  static const List<String> supportedLanguages = [
    'English',
    'Spanish',
    'French',
    'German'
  ];

  LanguageProvider(this._prefs)
      : _selectedLanguage = _prefs.getString(_languageKey) ?? 'English' {
    // Ensure the language is properly initialized from storage
    _loadLanguage();
  }

  String get selectedLanguage => _selectedLanguage;
  List<String> get languages => supportedLanguages;

  Future<void> _loadLanguage() async {
    try {
      _selectedLanguage = _prefs.getString(_languageKey) ?? 'English';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading language: $e');
      _selectedLanguage = 'English'; // Fallback to English
    }
  }

  Future<void> setLanguage(String language) async {
    if (!supportedLanguages.contains(language)) {
      debugPrint('Unsupported language: $language');
      return;
    }

    String previousLanguage = _selectedLanguage;
    try {
      _selectedLanguage = language;
      await _prefs.setString(_languageKey, language);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving language: $e');
      // Revert to previous language if saving fails
      _selectedLanguage = previousLanguage;
      notifyListeners();
    }
  }
}