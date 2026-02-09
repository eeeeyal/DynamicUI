import 'package:flutter/material.dart';

class AppConfig {
  final String version;
  final List<ScreenConfig> screens;
  final ThemeConfig theme;

  AppConfig({
    required this.version,
    required this.screens,
    required this.theme,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      version: json['version'] as String? ?? '1.0.0',
      screens: (json['screens'] as List<dynamic>?)
              ?.map((e) => ScreenConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      theme: json['theme'] != null
          ? ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>)
          : ThemeConfig.defaultTheme(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'screens': screens.map((e) => e.toJson()).toList(),
      'theme': theme.toJson(),
    };
  }
}

class ScreenConfig {
  final String id;
  final String type;
  final String title;
  final List<ScreenItem> items;
  final String? htmlPath; // Path to HTML file for HTML screens

  ScreenConfig({
    required this.id,
    required this.type,
    required this.title,
    required this.items,
    this.htmlPath,
  });

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    return ScreenConfig(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ScreenItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      htmlPath: json['htmlPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'items': items.map((e) => e.toJson()).toList(),
      if (htmlPath != null) 'htmlPath': htmlPath,
    };
  }
}

class ScreenItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? icon;
  final String? route;

  ScreenItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.route,
  });

  factory ScreenItem.fromJson(Map<String, dynamic> json) {
    return ScreenItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      icon: json['icon'] as String?,
      route: json['route'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'route': route,
    };
  }
}

class ThemeConfig {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;

  ThemeConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      primaryColor: json['primaryColor'] as String? ?? '#1976D2',
      secondaryColor: json['secondaryColor'] as String? ?? '#424242',
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
    );
  }

  factory ThemeConfig.defaultTheme() {
    return ThemeConfig(
      primaryColor: '#1976D2',
      secondaryColor: '#424242',
      backgroundColor: '#FFFFFF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundColor': backgroundColor,
    };
  }

  Color get primaryColorValue {
    return Color(int.parse(primaryColor.replaceFirst('#', '0xFF')));
  }

  Color get secondaryColorValue {
    return Color(int.parse(secondaryColor.replaceFirst('#', '0xFF')));
  }

  Color get backgroundColorValue {
    return Color(int.parse(backgroundColor.replaceFirst('#', '0xFF')));
  }
}

