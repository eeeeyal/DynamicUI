import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/config_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageService.instance.init();
  
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
          create: (_) => ConfigService()..loadConfig(),
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

