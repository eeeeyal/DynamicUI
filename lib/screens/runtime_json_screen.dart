import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io' if (dart.library.html) 'package:dynamic_ui_app/utils/web_stub.dart' as io;
import '../models/app_config.dart';
import '../runtime/widgets/dynamic_renderer.dart';
import '../runtime/controllers/runtime_controller.dart';
import '../runtime/services/json_loader_service.dart';
import '../runtime/handlers/action_handler.dart';
import '../services/config_service.dart';

/// Screen that renders JSON-based screens using the Runtime Engine
class RuntimeJsonScreen extends StatefulWidget {
  final ScreenConfig screenConfig;
  final ThemeConfig themeConfig;
  final String? assetsPath;

  const RuntimeJsonScreen({
    super.key,
    required this.screenConfig,
    required this.themeConfig,
    this.assetsPath,
  });

  @override
  State<RuntimeJsonScreen> createState() => _RuntimeJsonScreenState();
}

class _RuntimeJsonScreenState extends State<RuntimeJsonScreen> {
  Map<String, dynamic>? _screenJson;
  bool _isLoading = true;
  String? _error;
  RuntimeController? _runtimeController;
  ActionHandler? _actionHandler;
  String? _lastAssetsPath;
  String? _lastScreenId;

  @override
  void initState() {
    super.initState();
    _lastAssetsPath = widget.assetsPath;
    _lastScreenId = widget.screenConfig.id;
    _loadScreenJson();
  }

  @override
  void didUpdateWidget(RuntimeJsonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if assetsPath or screenConfig changed
    if (oldWidget.assetsPath != widget.assetsPath || 
        oldWidget.screenConfig.id != widget.screenConfig.id) {
      _lastAssetsPath = widget.assetsPath;
      _lastScreenId = widget.screenConfig.id;
      _loadScreenJson();
    }
  }

  @override
  void dispose() {
    _runtimeController?.dispose();
    super.dispose();
  }

  Future<void> _loadScreenJson() async {
    try {
      debugPrint('🔄 Loading screen JSON for: ${widget.screenConfig.id}');
      debugPrint('📦 ScreenConfig.screenJson: ${widget.screenConfig.screenJson != null}');
      debugPrint('📁 Assets path: ${widget.assetsPath}');
      
      // Get screenJson from screenConfig (stored during conversion)
      _screenJson = widget.screenConfig.screenJson;
      debugPrint('✅ Got screenJson from config: ${_screenJson != null}');
      
      if (_screenJson == null) {
        debugPrint('⚠️ screenJson is null, trying to load from assetsPath...');
        // Try to load from assetsPath as fallback
        if (widget.assetsPath != null && !kIsWeb) {
          // Find routes.json - could be in root or in a subdirectory
          io.File? routesFile;
          String? actualAssetsPath = widget.assetsPath;
          
          // Try root first
          routesFile = io.File('${widget.assetsPath}/routes.json');
          if (!await routesFile.exists()) {
            // Try to find in subdirectories
            final dir = io.Directory(widget.assetsPath!);
            await for (final entity in dir.list(recursive: false)) {
              if (entity is io.Directory) {
                final subRoutesFile = io.File('${entity.path}/routes.json');
                if (await subRoutesFile.exists()) {
                  routesFile = subRoutesFile;
                  actualAssetsPath = entity.path;
                  break;
                }
              }
            }
          }
          
          if (routesFile != null && await routesFile.exists()) {
            final routesContent = await routesFile.readAsString();
            final routes = jsonDecode(routesContent) as Map<String, dynamic>;
            
            final screenId = widget.screenConfig.id;
            if (routes.containsKey(screenId)) {
              final screenPath = routes[screenId] as String;
              final screenFile = io.File('$actualAssetsPath/$screenPath');
              if (await screenFile.exists()) {
                final screenContent = await screenFile.readAsString();
                _screenJson = jsonDecode(screenContent) as Map<String, dynamic>;
              }
            }
          }
        }
      }

      if (_screenJson == null) {
        debugPrint('❌ Screen JSON is null for screen: ${widget.screenConfig.id}');
        throw Exception('Screen JSON not found for screen: ${widget.screenConfig.id}');
      }

      debugPrint('✅ Screen JSON loaded: ${_screenJson!.keys.toList()}');

      // Create RuntimeController and ActionHandler if we have assetsPath
      if (widget.assetsPath != null) {
        debugPrint('🔧 Creating RuntimeController with assetsPath: ${widget.assetsPath}');
        final jsonLoader = JsonLoaderService(widget.assetsPath!);
        _runtimeController = RuntimeController(jsonLoader);
        
        // Load initial state from state.json
        final initialState = await jsonLoader.loadState();
        
        await _runtimeController!.initialize(
          initialState: initialState,
        );
        // ActionHandler will be created in build() with context
        debugPrint('✅ RuntimeController initialized');
      } else {
        debugPrint('⚠️ assetsPath is null, cannot create RuntimeController');
      }

      setState(() {
        _isLoading = false;
      });
      debugPrint('✅ Screen loading complete');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ConfigService changes for auto-update
    return Consumer<ConfigService>(
      builder: (context, configService, child) {
        // Check if config or assetsPath changed
        final currentAssetsPath = configService.assetsPath;
        final currentConfig = configService.config;
        
        if (currentConfig != null && currentAssetsPath != null) {
          // Find the current screen config
          final currentScreenConfig = currentConfig.screens.firstWhere(
            (screen) => screen.id == widget.screenConfig.id,
            orElse: () => widget.screenConfig,
          );
          
          // Check if assetsPath changed or screen config changed
          if (currentAssetsPath != _lastAssetsPath || 
              currentScreenConfig.screenJson != _screenJson) {
            // Reload screen JSON if assetsPath changed
            if (currentAssetsPath != _lastAssetsPath) {
              _lastAssetsPath = currentAssetsPath;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _reloadScreenJson(currentAssetsPath, currentScreenConfig);
              });
            } else if (currentScreenConfig.screenJson != null && 
                       currentScreenConfig.screenJson != _screenJson) {
              // Screen JSON changed in config, update it
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateScreenJson(currentScreenConfig);
              });
            }
          }
        }

        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.screenConfig.title),
              backgroundColor: _parseColor(widget.themeConfig.primaryColor),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_error != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.screenConfig.title),
              backgroundColor: _parseColor(widget.themeConfig.primaryColor),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                ],
              ),
            ),
          );
        }

        if (_screenJson == null || _runtimeController == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.screenConfig.title),
              backgroundColor: _parseColor(widget.themeConfig.primaryColor),
            ),
            body: const Center(
              child: Text('Screen data not available'),
            ),
          );
        }

        // Create ActionHandler with context and configService for navigation
        final actionHandler = ActionHandler(
          _runtimeController!,
          context: context,
          configService: configService,
          themeConfig: widget.themeConfig,
          assetsPath: currentAssetsPath ?? widget.assetsPath,
        );

        return DynamicRenderer(
          json: _screenJson!,
          runtimeController: _runtimeController!,
          actionHandler: actionHandler,
          isRTL: _runtimeController!.isRTL,
        );
      },
    );
  }

  Future<void> _reloadScreenJson(String assetsPath, ScreenConfig screenConfig) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🔄 Reloading screen JSON for: ${screenConfig.id}');
      debugPrint('📁 New assets path: $assetsPath');
      
      // Load screen JSON from new assetsPath
      if (!kIsWeb) {
        // Find routes.json
        io.File? routesFile;
        String? actualAssetsPath = assetsPath;
        
        // Try root first
        routesFile = io.File('$assetsPath/routes.json');
        if (!await routesFile.exists()) {
          // Try to find in subdirectories
          final dir = io.Directory(assetsPath);
          await for (final entity in dir.list(recursive: false)) {
            if (entity is io.Directory) {
              final subRoutesFile = io.File('${entity.path}/routes.json');
              if (await subRoutesFile.exists()) {
                routesFile = subRoutesFile;
                actualAssetsPath = entity.path;
                break;
              }
            }
          }
        }
        
        if (routesFile != null && await routesFile.exists()) {
          final routesContent = await routesFile.readAsString();
          final routes = jsonDecode(routesContent) as Map<String, dynamic>;
          
          final screenId = screenConfig.id;
          if (routes.containsKey(screenId)) {
            final screenPath = routes[screenId] as String;
            final screenFile = io.File('$actualAssetsPath/$screenPath');
            if (await screenFile.exists()) {
              final screenContent = await screenFile.readAsString();
              final newScreenJson = jsonDecode(screenContent) as Map<String, dynamic>;
              
              // Update RuntimeController with new assetsPath
              if (_runtimeController != null) {
                // Dispose old controller
                _runtimeController!.dispose();
              }
              
              if (actualAssetsPath != null) {
                final jsonLoader = JsonLoaderService(actualAssetsPath);
                _runtimeController = RuntimeController(jsonLoader);
                
                // Load initial state from state.json
                final initialState = await jsonLoader.loadState();
                
                await _runtimeController!.initialize(
                  initialState: initialState,
                );
              } else {
                throw Exception('actualAssetsPath is null');
              }
              
              setState(() {
                _screenJson = newScreenJson;
                _isLoading = false;
              });
              
              debugPrint('✅ Screen JSON reloaded successfully');
              return;
            }
          }
        }
      }
      
      // Fallback: use screenConfig.screenJson if available
      if (screenConfig.screenJson != null) {
        setState(() {
          _screenJson = screenConfig.screenJson;
          _isLoading = false;
        });
        debugPrint('✅ Screen JSON updated from config');
        return;
      }
      
      throw Exception('Failed to reload screen JSON');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('❌ Error reloading screen JSON: $e');
    }
  }

  void _updateScreenJson(ScreenConfig screenConfig) {
    if (screenConfig.screenJson != null && screenConfig.screenJson != _screenJson) {
      setState(() {
        _screenJson = screenConfig.screenJson;
      });
      debugPrint('✅ Screen JSON updated from config');
    }
  }

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.blue;
  }
}

