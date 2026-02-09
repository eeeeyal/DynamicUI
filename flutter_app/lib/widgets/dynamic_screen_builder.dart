import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../screens/dynamic_list_screen.dart';
import '../screens/html_screen.dart';

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
    switch (screenConfig.type) {
      case 'list':
        return DynamicListScreen(
          screenConfig: screenConfig,
          themeConfig: themeConfig,
          assetsPath: assetsPath,
        );
      case 'html':
        return HtmlScreen(
          screenConfig: screenConfig,
          themeConfig: themeConfig,
          assetsPath: assetsPath,
        );
      case 'form':
        // TODO: Implement form screen
        return _buildPlaceholder('Form Screen');
      case 'detail':
        // TODO: Implement detail screen
        return _buildPlaceholder('Detail Screen');
      default:
        return _buildPlaceholder('Unknown Screen Type: ${screenConfig.type}');
    }
  }

  Widget _buildPlaceholder(String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenConfig.title),
        backgroundColor: themeConfig.primaryColorValue,
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}

