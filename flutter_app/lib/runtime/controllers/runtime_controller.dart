import 'package:flutter/foundation.dart';
import '../services/json_loader_service.dart';
import '../engine/expression_engine.dart';

/// Controller for managing runtime state and navigation
class RuntimeController extends ChangeNotifier {
  final JsonLoaderService _jsonLoader;
  
  Map<String, dynamic>? _appConfig;
  Map<String, dynamic>? _routes;
  Map<String, dynamic>? _styles;
  Map<String, dynamic>? _actions;
  Map<String, dynamic>? _currentScreen;
  Map<String, dynamic> _state = {}; // Runtime state for bindings
  String? _currentRoute;
  bool _isLoading = false;
  String? _error;

  RuntimeController(this._jsonLoader);

  Map<String, dynamic>? get appConfig => _appConfig;
  Map<String, dynamic>? get routes => _routes;
  Map<String, dynamic>? get styles => _styles;
  Map<String, dynamic>? get actions => _actions;
  Map<String, dynamic>? get currentScreen => _currentScreen;
  Map<String, dynamic> get state => _state;
  String? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get runtimePath => _jsonLoader.runtimePath;
  
  /// Get value from state
  dynamic getValue(String key) {
    return _state[key];
  }
  
  /// Set value in state and notify listeners
  void setValue(String key, dynamic value) {
    _state[key] = value;
    Future.microtask(() {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }
  
  /// Evaluate a boolean expression against state
  bool evaluate(String expression) {
    return ExpressionEngine.evaluate(expression, _state);
  }
  
  /// Execute an action by action ID
  Future<void> executeAction(String actionName) async {
    final action = _actions?[actionName];
    if (action == null) {
      debugPrint('⚠️ Action not found: $actionName');
      return;
    }
    
    final actionType = action['type'] as String?;
    
    switch (actionType) {
      case 'navigation':
        final route = action['route'] as String?;
        if (route != null) {
          await loadRoute(route);
        }
        break;
        
      case 'logic':
        final expression = action['expression'] as String?;
        if (expression != null) {
          // Evaluate expression (may update state)
          ExpressionEngine.evaluate(expression, _state);
          Future.microtask(() {
            if (hasListeners) {
              notifyListeners();
            }
          });
        }
        break;
        
      default:
        debugPrint('⚠️ Unknown action type: $actionType');
    }
  }

  /// Initialize runtime - load all configuration files
  Future<void> initialize({
    Map<String, dynamic>? initialState,
    Map<String, dynamic>? initialActions,
    Map<String, dynamic>? initialScreens,
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
      // Initialize state if provided
      if (initialState != null) {
        _state = Map<String, dynamic>.from(initialState);
      }
      
      // Load all configuration files
      _appConfig = await _jsonLoader.loadAppConfig();
      
      // Try to load routes.json (may not exist in new format)
      try {
        _routes = await _jsonLoader.loadRoutes();
      } catch (e) {
        debugPrint('⚠️ routes.json not found, using default route');
        _routes = {'main': 'screens/main.json'}; // Default for new format
      }
      
      _styles = await _jsonLoader.loadStyles();
      
      // Merge initial actions with loaded actions
      final loadedActions = await _jsonLoader.loadActions();
      if (initialActions != null) {
        _actions = {...loadedActions, ...initialActions};
      } else {
        _actions = loadedActions;
      }

      // Load initial route from app.json
      final initialRoute = _appConfig?['initialRoute'] as String? ?? 'main';
      await loadRoute(initialRoute);

      _isLoading = false;
      
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  /// Load a specific route by name
  Future<void> loadRoute(String routeName) async {
    try {
      _currentScreen = await _jsonLoader.loadScreen(routeName);
      _currentRoute = routeName;
      
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    } catch (e) {
      _error = 'Failed to load route "$routeName": $e';
      
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  /// Get action configuration by action ID
  Map<String, dynamic>? getAction(String actionId) {
    return _actions?[actionId] as Map<String, dynamic>?;
  }

  /// Check if RTL is enabled
  bool get isRTL {
    return _appConfig?['rtl'] as bool? ?? false;
  }
}

