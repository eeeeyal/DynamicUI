import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'package:dynamic_ui_app/utils/web_stub.dart' as io;
import 'services/config_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageService.instance.init();
  
  // Note: WebView platform should be initialized automatically by the plugin
  // If you encounter issues, ensure WebView2 Runtime is installed on Windows
  // Download from: https://developer.microsoft.com/en-us/microsoft-edge/webview2/
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConfigService(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Dynamic UI',
            theme: themeService.getThemeData(),
            darkTheme: themeService.getThemeData(),
            themeMode: themeService.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

