import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../screens/runtime_json_screen.dart';
import '../screens/html_screen.dart';

/// Builder widget that renders screens using the Runtime Engine or HTML
class DynamicScreenBuilder extends StatelessWidget {
  final ScreenConfig screenConfig;
  final ThemeConfig themeConfig;
  final String? assetsPath;

  const DynamicScreenBuilder({
    super.key,
    required this.screenConfig,
    required this.themeConfig,
    this.assetsPath,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is an HTML screen
    if (screenConfig.type == 'html' && screenConfig.htmlPath != null) {
      final htmlPath = assetsPath != null 
          ? '$assetsPath/${screenConfig.htmlPath}'
          : screenConfig.htmlPath!;
      
      return HtmlScreen(
        htmlPath: htmlPath,
        assetsPath: assetsPath,
        isRTL: themeConfig.rtl ?? false,
      );
    }
    
    // All other screens use Runtime Engine
    return RuntimeJsonScreen(
      screenConfig: screenConfig,
      themeConfig: themeConfig,
      assetsPath: assetsPath,
    );
  }
}

