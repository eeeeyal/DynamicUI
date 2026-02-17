import 'package:flutter/material.dart';

/// Engine for applying style properties to widgets
class StyleEngine {
  /// Apply style properties from JSON to a widget
  static Widget apply(Map<String, dynamic> json, Widget child) {
    final style = json['style'] as Map<String, dynamic>?;
    if (style == null) return child;
    
    Widget styled = child;
    
    // Padding
    final padding = style['padding'];
    if (padding != null) {
      final paddingValue = padding is int ? padding.toDouble() : padding as double?;
      if (paddingValue != null && paddingValue > 0) {
        styled = Padding(
          padding: EdgeInsets.all(paddingValue),
          child: styled,
        );
      }
    }
    
    // Background color
    final background = style['background'] as String?;
    if (background != null) {
      final color = _parseColor(background);
      if (color != null) {
        styled = Container(
          color: color,
          child: styled,
        );
      }
    }
    
    // Border radius
    final radius = style['radius'];
    if (radius != null) {
      final radiusValue = radius is int ? radius.toDouble() : radius as double?;
      if (radiusValue != null && radiusValue > 0) {
        styled = ClipRRect(
          borderRadius: BorderRadius.circular(radiusValue),
          child: styled,
        );
      }
    }
    
    // Elevation (shadow)
    final elevation = style['elevation'];
    if (elevation != null) {
      final elevationValue = elevation is int ? elevation.toDouble() : elevation as double?;
      if (elevationValue != null && elevationValue > 0) {
        // Wrap in Material to support elevation
        styled = Material(
          elevation: elevationValue,
          color: Colors.transparent,
          child: styled,
        );
      }
    }
    
    return styled;
  }
  
  /// Parse color from hex string
  static Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    
    try {
      // Remove # if present
      String hex = colorString.replaceFirst('#', '');
      
      // Handle 3-digit hex
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      }
      
      // Add alpha if missing
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return null;
    }
  }
}




