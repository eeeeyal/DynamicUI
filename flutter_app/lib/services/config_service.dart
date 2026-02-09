import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import 'zip_service.dart';
import 'storage_service.dart';

class ConfigService extends ChangeNotifier {
  final ZipService _zipService = ZipService();
  final StorageService _storageService = StorageService.instance;

  AppConfig? _config;
  bool _isLoading = false;
  String? _error;
  String? _assetsPath;

  AppConfig? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get assetsPath => _assetsPath;

  /// Load config from ZIP (online or offline)
  /// Supports two formats:
  /// 1. JSON config inside ZIP (config.json)
  /// 2. Separate JSON config URL + ZIP assets URL
  Future<void> loadConfig({
    String? zipUrl, 
    String? jsonConfigUrl,
    bool forceUpdate = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from cache first (if not forcing update)
      if (!forceUpdate) {
        final cachedConfig = await _storageService.getCachedConfig();
        if (cachedConfig != null) {
          _config = cachedConfig;
          _assetsPath = await _zipService.getExtractedAssetsPath();
          _isLoading = false;
          notifyListeners();
          
          // Check for updates in background
          if (zipUrl != null) {
            _checkForUpdates(zipUrl);
          }
          return;
        }
      }

      Map<String, dynamic> configJson;
      
      // Format 2: Separate JSON config + ZIP assets
      if (jsonConfigUrl != null) {
        // Download JSON config separately
        configJson = await _zipService.downloadJsonConfig(jsonConfigUrl);
        
        // Download ZIP assets if provided
        if (zipUrl != null) {
          final zipPath = await _zipService.downloadZip(zipUrl);
          await _zipService.extractAssets(zipPath);
        }
      } 
      // Format 1: JSON config inside ZIP (default)
      else {
        // Load from server
        if (zipUrl == null) {
          zipUrl = await _zipService.getConfigUrl();
          if (zipUrl == null) {
            throw Exception('No ZIP URL configured');
          }
        }

        // Download and extract ZIP
        final zipPath = await _zipService.downloadZip(zipUrl);
        configJson = await _zipService.extractAndParseConfig(zipPath);
      }
      
      // Parse config
      _config = AppConfig.fromJson(configJson);
      _assetsPath = await _zipService.getExtractedAssetsPath();

      // Save version
      if (_config != null) {
        await _zipService.saveLastVersion(_config!.version);
        await _storageService.cacheConfig(_config!);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      
      // Try to load from cache as fallback
      final cachedConfig = await _storageService.getCachedConfig();
      if (cachedConfig != null) {
        _config = cachedConfig;
        _assetsPath = await _zipService.getExtractedAssetsPath();
      }
      
      notifyListeners();
    }
  }

  /// Check for updates in background
  Future<void> _checkForUpdates(String zipUrl) async {
    try {
      // Download ZIP to check version
      final zipPath = await _zipService.downloadZip(zipUrl);
      final configJson = await _zipService.extractAndParseConfig(zipPath);
      final newConfig = AppConfig.fromJson(configJson);

      if (_config == null || newConfig.version != _config!.version) {
        // Update available
        _config = newConfig;
        _assetsPath = await _zipService.getExtractedAssetsPath();
        await _zipService.saveLastVersion(newConfig.version);
        await _storageService.cacheConfig(newConfig);
        notifyListeners();
      }
    } catch (e) {
      // Silent fail - keep using cached config
      debugPrint('Update check failed: $e');
    }
  }

  /// Get asset file path
  String? getAssetPath(String? relativePath) {
    if (relativePath == null || _assetsPath == null) {
      return null;
    }
    return '$_assetsPath/$relativePath';
  }
}

