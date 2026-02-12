import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/runtime_controller.dart';
import '../../../models/app_config.dart';
import '../../../widgets/dynamic_screen_builder.dart';
import '../../../services/config_service.dart';
import '../plugins/platform_plugins.dart';

/// Handler for executing actions defined in actions.json
class ActionHandler {
  final RuntimeController _runtimeController;
  final BuildContext? _context;
  final ConfigService? _configService;
  final ThemeConfig? _themeConfig;
  final String? _assetsPath;

  ActionHandler(
    this._runtimeController, {
    BuildContext? context,
    ConfigService? configService,
    ThemeConfig? themeConfig,
    String? assetsPath,
  }) : _context = context,
       _configService = configService,
       _themeConfig = themeConfig,
       _assetsPath = assetsPath;

  /// Execute an action by action ID
  Future<void> executeAction(String actionId, {Map<String, dynamic>? context}) async {
    final action = _runtimeController.getAction(actionId);
    
    if (action == null) {
      debugPrint('⚠️ Action not found: $actionId');
      return;
    }

    final actionType = action['type'] as String?;
    
    switch (actionType) {
      case 'navigation':
        await _handleNavigation(action);
        break;
      case 'api':
        await _handleApi(action, context: context);
        break;
      default:
        debugPrint('⚠️ Unknown action type: $actionType');
    }
  }

  /// Handle navigation action
  Future<void> _handleNavigation(Map<String, dynamic> action) async {
    final route = action['route'] as String?;
    if (route == null) {
      debugPrint('⚠️ Navigation action missing route');
      return;
    }

    // If we have context and configService, navigate using Navigator
    if (_context != null && _configService != null && _themeConfig != null) {
      final config = _configService.config;
      if (config != null) {
        // Find the screen config for this route
        final screenConfig = config.screens.firstWhere(
          (screen) => screen.id == route,
          orElse: () => config.screens.first, // Fallback to first screen
        );

        debugPrint('🧭 Navigating to route: $route');
        
        // Navigate to the new screen
        Navigator.of(_context).push(
          MaterialPageRoute(
            builder: (context) => DynamicScreenBuilder(
              screenConfig: screenConfig,
              themeConfig: _themeConfig,
              assetsPath: _assetsPath,
            ),
          ),
        );
        return;
      }
    }

    // Fallback: update RuntimeController
    debugPrint('🧭 Updating RuntimeController route: $route');
    await _runtimeController.loadRoute(route);
  }

  /// Handle API action (mock for now)
  Future<void> _handleApi(Map<String, dynamic> action, {Map<String, dynamic>? context}) async {
    final method = action['method'] as String? ?? 'GET';
    final endpoint = action['endpoint'] as String?;
    
    debugPrint('🌐 API Action: $method $endpoint');
    debugPrint('📦 Context: $context');
    
    // TODO: Implement actual API call
    // For now, just log the action
    debugPrint('✅ API action executed (mock)');
  }

  /// Handle platform-specific actions
  Future<void> handlePlatformAction(String actionName, {Map<String, dynamic>? params}) async {
    final plugins = PlatformPlugins();
    
    switch (actionName) {
      case 'requestLocationPermission':
        final result = await plugins.requestLocationPermission();
        if (result != null && result['success'] == true) {
          // Update state with location
          _runtimeController.setValue('location', result);
        }
        break;
        
      case 'pickImage':
        final result = await plugins.pickImageFromGallery();
        if (result != null && result['success'] == true) {
          _runtimeController.setValue('selectedImage', result);
        }
        break;
        
      case 'takePicture':
        final result = await plugins.takePicture();
        if (result != null && result['success'] == true) {
          _runtimeController.setValue('capturedImage', result);
        }
        break;
        
      case 'getContacts':
        final result = await plugins.getContacts();
        if (result != null && result['success'] == true) {
          _runtimeController.setValue('contacts', result['contacts']);
        }
        break;
        
      case 'sendNotification':
        final title = params?['title'] as String? ?? 'התראה';
        final body = params?['body'] as String? ?? '';
        await plugins.sendNotification(title, body);
        break;
        
      case 'getStorageInfo':
        final result = await plugins.getStorageInfo();
        if (result != null) {
          _runtimeController.setValue('storageInfo', result);
        }
        break;
        
      case 'getNetworkStatus':
        final result = await plugins.getNetworkStatus();
        if (result != null) {
          _runtimeController.setValue('networkStatus', result);
        }
        break;
        
      default:
        debugPrint('⚠️ Unknown platform action: $actionName');
    }
  }
}

