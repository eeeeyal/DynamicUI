import 'package:flutter/material.dart';
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
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final configService = context.read<ConfigService>();
    
    // TODO: Replace with your actual ZIP URL
    // For now, you can set it via the text field
    final zipUrl = _zipUrl ?? 'https://your-server.com/api/app/config.zip';
    
    await configService.loadConfig(zipUrl: zipUrl);
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
                    onPressed: () => _loadConfig(),
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
            appBar: AppBar(title: const Text('Setup')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Please enter ZIP URL',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  _buildUrlInput(configService),
                ],
              ),
            ),
          );
        }

        final config = configService.config!;
        final themeConfig = config.theme;

        // Find home screen or use first screen
        final homeScreenConfig = config.screens.firstWhere(
          (screen) => screen.id == 'home',
          orElse: () => config.screens.first,
        );

        return DynamicScreenBuilder(
          screenConfig: homeScreenConfig,
          themeConfig: themeConfig,
          assetsPath: configService.assetsPath,
        );
      },
    );
  }

  Widget _buildUrlInput(ConfigService configService) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _pickLocalFile(configService);
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose Local File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_zipUrl != null && _zipUrl!.isNotEmpty) {
                      await configService.loadConfig(
                        zipUrl: _zipUrl,
                        forceUpdate: true,
                      );
                    }
                  },
                  child: const Text('Load from URL'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocalFile(ConfigService configService) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'gz', 'gzip', 'html.gz'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loading local ZIP file...'),
              duration: Duration(seconds: 1),
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

