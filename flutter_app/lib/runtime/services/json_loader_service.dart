import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service to load JSON files from runtime directory
class JsonLoaderService {
  final String runtimePath;

  JsonLoaderService(this.runtimePath);

  /// Load app.json configuration
  Future<Map<String, dynamic>> loadAppConfig() async {
    try {
      final file = File('$runtimePath/app.json');
      if (!await file.exists()) {
        throw Exception('app.json not found in runtime directory');
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      debugPrint('✅ Loaded app.json');
      return json;
    } catch (e) {
      throw Exception('Failed to load app.json: $e');
    }
  }

  /// Load routes.json (optional - if not found, will use screens/main.json directly)
  Future<Map<String, dynamic>> loadRoutes() async {
    try {
      final file = File('$runtimePath/routes.json');
      if (!await file.exists()) {
        // If routes.json doesn't exist, check if screens/main.json exists
        // This supports the new format from html_to_runtime_converter_v2.py
        final mainScreenFile = File('$runtimePath/screens/main.json');
        if (await mainScreenFile.exists()) {
          debugPrint('⚠️ routes.json not found, using screens/main.json directly');
          // Return a routes map with "main" pointing to screens/main.json
          return {
            'main': 'screens/main.json',
          };
        }
        throw Exception('routes.json not found in runtime directory');
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      debugPrint('✅ Loaded routes.json');
      return json;
    } catch (e) {
      throw Exception('Failed to load routes.json: $e');
    }
  }

  /// Load styles.json
  Future<Map<String, dynamic>> loadStyles() async {
    try {
      final file = File('$runtimePath/styles.json');
      if (!await file.exists()) {
        // Return default styles if file doesn't exist
        return {
          'primaryColor': '#4f46e5',
          'secondaryColor': '#7c3aed',
          'backgroundColor': '#f3f4f6',
          'buttonRadius': 12,
          'font': 'Heebo',
        };
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      debugPrint('✅ Loaded styles.json');
      return json;
    } catch (e) {
      // Return default styles on error
      return {
        'primaryColor': '#4f46e5',
        'secondaryColor': '#7c3aed',
        'backgroundColor': '#f3f4f6',
        'buttonRadius': 12,
        'font': 'Heebo',
      };
    }
  }

  /// Load actions.json
  Future<Map<String, dynamic>> loadActions() async {
    try {
      final file = File('$runtimePath/actions.json');
      if (!await file.exists()) {
        return {};
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      debugPrint('✅ Loaded actions.json');
      return json;
    } catch (e) {
      return {};
    }
  }

  /// Load state.json (initial state)
  Future<Map<String, dynamic>> loadState() async {
    try {
      final file = File('$runtimePath/state.json');
      if (!await file.exists()) {
        return {};
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      debugPrint('✅ Loaded state.json');
      return json;
    } catch (e) {
      return {};
    }
  }

  /// Load a specific screen JSON file
  /// routeName should match a key in routes.json (e.g., "home", "settings")
  Future<Map<String, dynamic>> loadScreen(String routeName) async {
    try {
      // First, load routes to find the screen file path
      final routes = await loadRoutes();
      
      if (!routes.containsKey(routeName)) {
        throw Exception('Route "$routeName" not found in routes.json');
      }
      
      final screenPath = routes[routeName] as String;
      final file = File('$runtimePath/$screenPath');
      
      if (!await file.exists()) {
        throw Exception('Screen file not found: $screenPath');
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      debugPrint('✅ Loaded screen: $routeName');
      return json;
    } catch (e) {
      throw Exception('Failed to load screen "$routeName": $e');
    }
  }

  /// Get asset file path
  String? getAssetPath(String? relativePath) {
    if (relativePath == null) {
      return null;
    }
    return '$runtimePath/$relativePath';
  }
}

