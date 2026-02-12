import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/app_config.dart';
import 'zip_service.dart';
import 'storage_service.dart';

// Import dart:io only when not on web
// On web, file operations are not supported - use URL loading instead
import 'dart:io' if (dart.library.html) 'package:dynamic_ui_app/utils/web_stub.dart' show File, Directory;

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
      // Use Future.microtask to defer notifyListeners until after current build
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });

    try {
      // Try to load from cache first (if not forcing update)
      if (!forceUpdate) {
        final cachedConfig = await _storageService.getCachedConfig();
        if (cachedConfig != null) {
          _config = cachedConfig;
          _assetsPath = await _zipService.getExtractedAssetsPath();
          _isLoading = false;
          
          // Use Future.microtask to defer notifyListeners until after current build
          Future.microtask(() {
            if (hasListeners) {
              notifyListeners();
            }
          });
          
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
        // Load from server or local file
        if (zipUrl == null) {
          zipUrl = await _zipService.getConfigUrl();
          if (zipUrl == null) {
            throw Exception('No ZIP URL configured');
          }
        }

        // Check if it's a local HTML file
        if (zipUrl.endsWith('.html') || zipUrl.endsWith('.htm')) {
          if (kIsWeb) {
            throw Exception('Web platform: HTML file loading from local path not supported. Please use URL.');
          }
          
          // Handle HTML file directly
          final htmlFile = File(zipUrl);
          if (await htmlFile.exists()) {
            final htmlContent = await htmlFile.readAsString();
            final appDir = await getApplicationDocumentsDirectory();
            final extractDir = Directory('${appDir.path}/extracted');
            
            // Clean old extraction
            if (await extractDir.exists()) {
              await extractDir.delete(recursive: true);
            }
            await extractDir.create(recursive: true);
            
            // Save HTML file
            final savedHtmlFile = File('${extractDir.path}/index.html');
            await savedHtmlFile.writeAsString(htmlContent);
            
            // Create config from HTML
            configJson = {
              'version': '1.0.0',
              'screens': [
                {
                  'id': 'html_content',
                  'type': 'html',
                  'title': 'HTML Content',
                  'htmlPath': 'index.html',
                }
              ],
              'theme': {
                'primaryColor': '#1976D2',
                'secondaryColor': '#424242',
                'backgroundColor': '#FFFFFF',
              }
            };
            
            // Save config
            final configFile = File('${extractDir.path}/config.json');
            await configFile.writeAsString(jsonEncode(configJson));
            await _zipService.saveExtractedPath(extractDir.path);
          } else {
            throw Exception('HTML file not found: $zipUrl');
          }
        } else {
          // Download and extract ZIP
          final zipPath = await _zipService.downloadZip(zipUrl);
          configJson = await _zipService.extractAndParseConfig(zipPath);
        }
      }
      
      // Check if this is the new format (app.json) or old format (config.json)
      if (configJson.containsKey('appId') && configJson.containsKey('initialRoute')) {
        debugPrint('✅ Detected new format (app.json)');
        // New format: app.json - convert to old format for compatibility
        final extractedPath = await _zipService.getExtractedAssetsPath();
        debugPrint('📁 Extracted path: $extractedPath');
        
        if (extractedPath != null) {
          // Skip file operations on web - use URL loading instead
          if (kIsWeb) {
            throw Exception('Web platform: Please load ZIP from URL instead of local file');
          }
          
          // Find routes.json - could be in root or in a subdirectory
          // If not found, check for screens/main.json (new format from html_to_runtime_converter_v2.py)
          File? routesFile;
          String? actualExtractedPath = extractedPath;
          bool useNewFormat = false;
          
          // Try root first
          routesFile = File('$extractedPath/routes.json');
          if (!await routesFile.exists()) {
            // Try to find in subdirectories
            final dir = Directory(extractedPath);
            await for (final entity in dir.list(recursive: false)) {
              if (entity is Directory) {
                final subRoutesFile = File('${entity.path}/routes.json');
                if (await subRoutesFile.exists()) {
                  routesFile = subRoutesFile;
                  actualExtractedPath = entity.path;
                  debugPrint('✅ Found routes.json in subdirectory: ${entity.path}');
                  break;
                }
              }
            }
          }
          
          // If routes.json not found, check for screens/main.json (new format)
          if (routesFile == null || !await routesFile.exists()) {
            final mainScreenFile = File('$extractedPath/screens/main.json');
            if (await mainScreenFile.exists()) {
              debugPrint('✅ Found screens/main.json (new format without routes.json)');
              useNewFormat = true;
              actualExtractedPath = extractedPath;
            } else {
              // Try subdirectories for screens/main.json
              final dir = Directory(extractedPath);
              await for (final entity in dir.list(recursive: false)) {
                if (entity is Directory) {
                  final subMainScreenFile = File('${entity.path}/screens/main.json');
                  if (await subMainScreenFile.exists()) {
                    debugPrint('✅ Found screens/main.json in subdirectory: ${entity.path}');
                    useNewFormat = true;
                    actualExtractedPath = entity.path;
                    break;
                  }
                }
              }
            }
          }
          
          if (routesFile != null) {
            debugPrint('📄 Routes file path: ${routesFile.path}');
            debugPrint('📄 Routes file exists: ${await routesFile.exists()}');
          } else {
            debugPrint('⚠️ routes.json not found, using new format with screens/main.json');
          }
          debugPrint('📁 Using extracted path: $actualExtractedPath');
          
          // Initialize screens list
          final screens = <Map<String, dynamic>>[];
          
          if (useNewFormat) {
            // New format: Load screens/main.json directly
            final mainScreenFile = File('$actualExtractedPath/screens/main.json');
            if (await mainScreenFile.exists()) {
              final screenContent = await mainScreenFile.readAsString();
              final screenJson = jsonDecode(screenContent) as Map<String, dynamic>;
              
              // Convert new format to old format
              final screenId = screenJson['id'] as String? ?? 'main';
              final layout = screenJson['layout'] as Map<String, dynamic>?;
              
              // Convert layout to body format for compatibility
              final bodyJson = layout != null ? {
                'type': layout['type'] ?? 'column',
                'children': layout['children'] ?? [],
              } : null;
              
              screens.add({
                'id': screenId,
                'type': 'runtime',
                'title': screenId,
                'items': <Map<String, dynamic>>[],
                'htmlPath': null,
                'screenJson': {
                  'type': 'screen',
                  'id': screenId,
                  'layout': layout,
                  'body': bodyJson, // Add body for compatibility
                },
              });
              
              debugPrint('✅ Loaded screen from screens/main.json');
              
              // Load styles.json if exists
              final stylesFile = File('$actualExtractedPath/styles.json');
              Map<String, dynamic> styles = {};
              if (await stylesFile.exists()) {
                final stylesContent = await stylesFile.readAsString();
                styles = jsonDecode(stylesContent) as Map<String, dynamic>;
                debugPrint('✅ Loaded styles.json');
              } else {
                debugPrint('⚠️ styles.json not found, using defaults');
              }
              
              configJson = {
                'version': configJson['version'] ?? '1.0.0',
                'screens': screens,
                'theme': {
                  'primaryColor': styles['primaryColor'] ?? '#4f46e5',
                  'secondaryColor': styles['secondaryColor'] ?? '#7c3aed',
                  'backgroundColor': styles['backgroundColor'] ?? '#f3f4f6',
                },
              };
              
              debugPrint('✅ Converted config with ${screens.length} screens (new format)');
            } else {
              throw Exception('screens/main.json not found in extracted ZIP');
            }
          } else if (routesFile != null && await routesFile.exists()) {
            final routesContent = await routesFile.readAsString();
            final routes = jsonDecode(routesContent) as Map<String, dynamic>;
            debugPrint('✅ Loaded routes.json with ${routes.length} routes: ${routes.keys.toList()}');
            
            // Load styles.json
            final stylesFile = File('$actualExtractedPath/styles.json');
            Map<String, dynamic> styles = {};
            if (await stylesFile.exists()) {
              final stylesContent = await stylesFile.readAsString();
              styles = jsonDecode(stylesContent) as Map<String, dynamic>;
              debugPrint('✅ Loaded styles.json');
            } else {
              debugPrint('⚠️ styles.json not found, using defaults');
            }
            
            // Convert to old format
            final screens = <Map<String, dynamic>>[];
            final totalRoutes = routes.length;
            int loadedCount = 0;
            int failedCount = 0;
            
            debugPrint('📦 Loading $totalRoutes screens...');
            
            for (final routeEntry in routes.entries) {
              try {
                final screenPath = routeEntry.value as String;
                final screenFile = File('$actualExtractedPath/$screenPath');
                
                // Only print detailed logs for first few screens or every 10th screen
                final shouldLogDetails = loadedCount < 3 || loadedCount % 10 == 0;
                
                if (shouldLogDetails) {
                  debugPrint('📄 Loading screen ${loadedCount + 1}/$totalRoutes: ${routeEntry.key}');
                }
                
                if (await screenFile.exists()) {
                  final screenContent = await screenFile.readAsString();
                  final screenJson = jsonDecode(screenContent) as Map<String, dynamic>;
                  
                  // Convert new format to old format
                  // New format: {type: "screen", id: "...", appBar: {...}, body: {...}}
                  // Old format: {id: "...", type: "...", title: "...", items: [...]}
                  
                  final appBar = screenJson['appBar'] as Map<String, dynamic>?;
                  final screenId = screenJson['id'] as String? ?? routeEntry.key;
                  final title = appBar?['title'] as String? ?? screenId;
                  
                  // For runtime screens, items should be empty - we use screenJson directly
                  // Don't convert body to items - ScreenItem expects id/title which body doesn't have
                  screens.add({
                    'id': screenId,
                    'type': 'runtime', // Use runtime type to render with DynamicRenderer
                    'title': title ?? screenId, // Ensure title is never null
                    'items': <Map<String, dynamic>>[], // Empty items - we use screenJson instead
                    'htmlPath': null, // We'll use the screen JSON directly
                    'screenJson': screenJson, // Store original JSON for rendering
                  });
                  
                  loadedCount++;
                  
                  if (shouldLogDetails) {
                    debugPrint('✅ Loaded screen: ${routeEntry.key}');
                  }
                } else {
                  failedCount++;
                  debugPrint('⚠️ Screen file not found: $screenPath (route: ${routeEntry.key})');
                }
              } catch (e) {
                failedCount++;
                debugPrint('❌ Error loading screen ${routeEntry.key}: $e');
              }
            }
            
            debugPrint('📊 Loading complete: $loadedCount/$totalRoutes screens loaded successfully');
            if (failedCount > 0) {
              debugPrint('⚠️ Failed to load $failedCount screen(s)');
            }
            
            if (screens.isEmpty) {
              throw Exception('No screens found in routes.json or screen files are missing');
            }
            
            configJson = {
              'version': configJson['version'] ?? '1.0.0',
              'screens': screens,
              'theme': {
                'primaryColor': styles['primaryColor'] ?? '#4f46e5',
                'secondaryColor': styles['secondaryColor'] ?? '#7c3aed',
                'backgroundColor': styles['backgroundColor'] ?? '#f3f4f6',
              },
            };
            
            debugPrint('✅ Converted config with ${screens.length} screens');
          } else {
            if (routesFile != null) {
              debugPrint('❌ routes.json not found at: ${routesFile.path}');
            } else {
              debugPrint('❌ routes.json not found in root or subdirectories');
            }
            throw Exception('routes.json not found in extracted ZIP');
          }
        } else {
          debugPrint('❌ Extracted path is null');
          throw Exception('Failed to get extracted assets path');
        }
      } else {
        debugPrint('ℹ️ Using old format (config.json)');
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
      
      // Use Future.microtask to defer notifyListeners until after current build
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      
      // Try to load from cache as fallback
      final cachedConfig = await _storageService.getCachedConfig();
      if (cachedConfig != null) {
        _config = cachedConfig;
        _assetsPath = await _zipService.getExtractedAssetsPath();
      }
      
      // Use Future.microtask to defer notifyListeners until after current build
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
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
        
        // Use Future.microtask to defer notifyListeners until after current build
        Future.microtask(() {
          if (hasListeners) {
            notifyListeners();
          }
        });
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

