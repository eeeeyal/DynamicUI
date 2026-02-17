import 'package:flutter/foundation.dart';

/// Engine for evaluating dynamic expressions and conditions
class ExpressionEngine {
  /// Evaluate a boolean expression against state
  /// Supports: ==, !=, &&, ||, >, <, >=, <=
  static bool evaluate(String expression, Map<String, dynamic> state) {
    try {
      // Remove whitespace
      expression = expression.trim();
      
      // Handle logical operators (&&, ||)
      if (expression.contains('&&')) {
        final parts = expression.split('&&');
        return parts.every((part) => evaluate(part.trim(), state));
      }
      
      if (expression.contains('||')) {
        final parts = expression.split('||');
        return parts.any((part) => evaluate(part.trim(), state));
      }
      
      // Handle comparison operators
      if (expression.contains('==')) {
        final parts = expression.split('==');
        if (parts.length != 2) return false;
        
        final left = _getValue(parts[0].trim(), state);
        final right = _getValue(parts[1].trim(), state);
        
        return left == right;
      }
      
      if (expression.contains('!=')) {
        final parts = expression.split('!=');
        if (parts.length != 2) return false;
        
        final left = _getValue(parts[0].trim(), state);
        final right = _getValue(parts[1].trim(), state);
        
        return left != right;
      }
      
      if (expression.contains('>=')) {
        final parts = expression.split('>=');
        if (parts.length != 2) return false;
        
        final left = _getNumericValue(parts[0].trim(), state);
        final right = _getNumericValue(parts[1].trim(), state);
        
        return left != null && right != null && left >= right;
      }
      
      if (expression.contains('<=')) {
        final parts = expression.split('<=');
        if (parts.length != 2) return false;
        
        final left = _getNumericValue(parts[0].trim(), state);
        final right = _getNumericValue(parts[1].trim(), state);
        
        return left != null && right != null && left <= right;
      }
      
      if (expression.contains('>')) {
        final parts = expression.split('>');
        if (parts.length != 2) return false;
        
        final left = _getNumericValue(parts[0].trim(), state);
        final right = _getNumericValue(parts[1].trim(), state);
        
        return left != null && right != null && left > right;
      }
      
      if (expression.contains('<')) {
        final parts = expression.split('<');
        if (parts.length != 2) return false;
        
        final left = _getNumericValue(parts[0].trim(), state);
        final right = _getNumericValue(parts[1].trim(), state);
        
        return left != null && right != null && left < right;
      }
      
      // If no operator, check if value exists and is truthy
      final value = _getValue(expression, state);
      if (value is bool) return value;
      if (value != null && value != '') return true;
      
      return false;
    } catch (e) {
      debugPrint('⚠️ Expression evaluation error: $e');
      return false;
    }
  }
  
  /// Get value from state or return as literal
  static dynamic _getValue(String key, Map<String, dynamic> state) {
    // Remove quotes if present
    key = key.replaceAll("'", '').replaceAll('"', '');
    
    // Check if it's a state key
    if (state.containsKey(key)) {
      return state[key];
    }
    
    // Return as literal string
    return key;
  }
  
  /// Get numeric value for comparison
  static double? _getNumericValue(String key, Map<String, dynamic> state) {
    final value = _getValue(key, state);
    
    if (value is num) {
      return value.toDouble();
    }
    
    if (value is String) {
      return double.tryParse(value);
    }
    
    return null;
  }
  
  /// Evaluate expression and return dynamic value (for bindings)
  static dynamic evaluateExpression(String expression, Map<String, dynamic> state) {
    try {
      // If it's just a state key, return the value
      final trimmed = expression.trim();
      if (state.containsKey(trimmed)) {
        return state[trimmed];
      }
      
      // Try to evaluate as boolean expression
      if (evaluate(trimmed, state)) {
        return true;
      }
      
      // Return as string literal
      return trimmed.replaceAll("'", '').replaceAll('"', '');
    } catch (e) {
      debugPrint('⚠️ Expression evaluation error: $e');
      return expression;
    }
  }
}




