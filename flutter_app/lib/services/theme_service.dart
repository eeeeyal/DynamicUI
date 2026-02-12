import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  ThemeMode _themeMode = ThemeMode.light;
  int _selectedThemeIndex = 0;
  
  ThemeMode get themeMode => _themeMode;
  int get selectedThemeIndex => _selectedThemeIndex;
  
  // רשימת themes מוגדרים מראש
  final List<AppTheme> _themes = [
    AppTheme(
      name: 'Light',
      primaryColor: const Color(0xFF1976D2),
      secondaryColor: const Color(0xFF424242),
      backgroundColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF000000),
    ),
    AppTheme(
      name: 'Dark',
      primaryColor: const Color(0xFF64B5F6),
      secondaryColor: const Color(0xFF90A4AE),
      backgroundColor: const Color(0xFF121212),
      textColor: const Color(0xFFFFFFFF),
    ),
    AppTheme(
      name: 'Blue',
      primaryColor: const Color(0xFF2196F3),
      secondaryColor: const Color(0xFF03A9F4),
      backgroundColor: const Color(0xFFE3F2FD),
      textColor: const Color(0xFF1976D2),
    ),
    AppTheme(
      name: 'Green',
      primaryColor: const Color(0xFF4CAF50),
      secondaryColor: const Color(0xFF66BB6A),
      backgroundColor: const Color(0xFFE8F5E9),
      textColor: const Color(0xFF2E7D32),
    ),
    AppTheme(
      name: 'Purple',
      primaryColor: const Color(0xFF9C27B0),
      secondaryColor: const Color(0xFFBA68C8),
      backgroundColor: const Color(0xFFF3E5F5),
      textColor: const Color(0xFF7B1FA2),
    ),
    AppTheme(
      name: 'Orange',
      primaryColor: const Color(0xFFFF9800),
      secondaryColor: const Color(0xFFFFB74D),
      backgroundColor: const Color(0xFFFFF3E0),
      textColor: const Color(0xFFE65100),
    ),
    AppTheme(
      name: 'Red',
      primaryColor: const Color(0xFFF44336),
      secondaryColor: const Color(0xFFEF5350),
      backgroundColor: const Color(0xFFFFEBEE),
      textColor: const Color(0xFFC62828),
    ),
    AppTheme(
      name: 'Teal',
      primaryColor: const Color(0xFF009688),
      secondaryColor: const Color(0xFF4DB6AC),
      backgroundColor: const Color(0xFFE0F2F1),
      textColor: const Color(0xFF00695C),
    ),
  ];
  
  List<AppTheme> get themes => _themes;
  AppTheme get currentTheme => _themes[_selectedThemeIndex];
  
  ThemeService() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_themeKey) ?? 0;
      if (savedIndex >= 0 && savedIndex < _themes.length) {
        _selectedThemeIndex = savedIndex;
        _themeMode = _selectedThemeIndex == 1 ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }
  
  Future<void> setTheme(int index) async {
    if (index >= 0 && index < _themes.length) {
      _selectedThemeIndex = index;
      _themeMode = index == 1 ? ThemeMode.dark : ThemeMode.light;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_themeKey, index);
      } catch (e) {
        debugPrint('Error saving theme: $e');
      }
      
      notifyListeners();
    }
  }
  
  ThemeData getThemeData() {
    final theme = currentTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      primaryColor: theme.primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.primaryColor,
        brightness: _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        primary: theme.primaryColor,
        secondary: theme.secondaryColor,
        surface: theme.backgroundColor,
      ),
      scaffoldBackgroundColor: theme.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: theme.backgroundColor,
        elevation: 2,
      ),
    );
  }
}

class AppTheme {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  
  AppTheme({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
  });
  
  String get primaryColorHex {
    final value = primaryColor.value.toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }
  
  String get secondaryColorHex {
    final value = secondaryColor.value.toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }
  
  String get backgroundColorHex {
    final value = backgroundColor.value.toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }
}


