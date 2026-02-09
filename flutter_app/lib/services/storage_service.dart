import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  static const String _cachedConfigKey = 'cached_app_config';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Cache app config locally
  Future<void> cacheConfig(AppConfig config) async {
    if (_prefs == null) {
      await init();
    }
    
    final jsonString = jsonEncode(config.toJson());
    await _prefs!.setString(_cachedConfigKey, jsonString);
  }

  /// Get cached app config
  Future<AppConfig?> getCachedConfig() async {
    if (_prefs == null) {
      await init();
    }

    final jsonString = _prefs!.getString(_cachedConfigKey);
    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppConfig.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Clear cached config
  Future<void> clearCache() async {
    if (_prefs == null) {
      await init();
    }
    await _prefs!.remove(_cachedConfigKey);
  }
}

