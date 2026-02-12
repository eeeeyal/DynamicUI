import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/config_service.dart';
import '../widgets/dynamic_screen_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _zipUrl;

  @override
  void initState() {
    super.initState();
    // Don't auto-load config - let user choose file manually
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigService>(
      builder: (context, configService, child) {
        if (configService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (configService.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${configService.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      // Retry by showing setup screen again
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 16),
                  _buildUrlInput(configService),
                ],
              ),
            ),
          );
        }

        if (configService.config == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dynamic UI - Load Configuration'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 80, color: Colors.blue),
                    const SizedBox(height: 24),
                    const Text(
                      'בחר קובץ ZIP או HTML',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose ZIP or HTML file',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    if (!kIsWeb) _buildFilePickerButtons(configService),
                    if (kIsWeb) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'Web Platform',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please use URL loading instead of file picker on web platform',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildUrlInput(configService),
                  ],
                ),
              ),
            ),
          );
        }

        final config = configService.config!;
        final themeConfig = config.theme;

        // Check if screens list is empty
        if (config.screens.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('No screens found in configuration'),
            ),
          );
        }

        // Find home screen or use first screen
        // For HTML screens, look for 'home' or any screen with 'home' in the id
        final homeScreenConfig = config.screens.firstWhere(
          (screen) => screen.id == 'home' || screen.id.endsWith('/home') || screen.id.contains('home.html'),
          orElse: () => config.screens.first,
        );

        debugPrint('🏠 Found home screen: ${homeScreenConfig.id}, type: ${homeScreenConfig.type}');
        debugPrint('📦 Screen has screenJson: ${homeScreenConfig.screenJson != null}');
        debugPrint('📁 Assets path: ${configService.assetsPath}');

        return DynamicScreenBuilder(
          screenConfig: homeScreenConfig,
          themeConfig: themeConfig,
          assetsPath: configService.assetsPath,
        );
      },
    );
  }

  Widget _buildFilePickerButtons(ConfigService configService) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await _pickLocalFile(configService, isZip: true);
            },
            icon: const Icon(Icons.archive, size: 28),
            label: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'בחר קובץ ZIP',
                style: TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await _pickLocalFile(configService, isZip: false);
            },
            icon: const Icon(Icons.code, size: 28),
            label: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'בחר קובץ HTML',
                style: TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlInput(ConfigService configService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'או הזן URL:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'ZIP/GZ URL',
                hintText: 'https://your-server.com/api/app/config.zip',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _zipUrl = value;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_zipUrl != null && _zipUrl!.isNotEmpty) {
                    await configService.loadConfig(
                      zipUrl: _zipUrl,
                      forceUpdate: true,
                    );
                  }
                },
                child: const Text('טען מ-URL'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocalFile(ConfigService configService, {required bool isZip}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: isZip ? FileType.custom : FileType.any,
        allowedExtensions: isZip ? ['zip', 'gz', 'gzip'] : ['html', 'htm'],
      );

      if (result != null) {
        // On web, file_picker returns bytes, not a path
        final filePath = result.files.single.path;
        
        if (filePath == null) {
          // Web platform - handle bytes directly
          if (result.files.single.bytes != null) {
            // For web, we need to handle this differently
            // For now, show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Web platform: Please use URL loading instead of file picker'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        }
        
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loading ${isZip ? 'ZIP' : 'HTML'} file...'),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // Load config from local file
        await configService.loadConfig(
          zipUrl: filePath,
          forceUpdate: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded: ${result.files.single.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

