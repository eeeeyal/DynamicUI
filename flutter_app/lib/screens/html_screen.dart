import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/app_config.dart';
import '../services/html_parser_service.dart';
import '../utils/responsive.dart';
import '../widgets/theme_selector.dart';
import '../services/theme_service.dart';

class HtmlScreen extends StatefulWidget {
  final ScreenConfig screenConfig;
  final ThemeConfig themeConfig;
  final String? assetsPath;

  const HtmlScreen({
    super.key,
    required this.screenConfig,
    required this.themeConfig,
    this.assetsPath,
  });

  @override
  State<HtmlScreen> createState() => _HtmlScreenState();
}

class _HtmlScreenState extends State<HtmlScreen> {
  String? _htmlContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    try {
      if (widget.screenConfig.htmlPath != null) {
        final htmlFile = File(widget.screenConfig.htmlPath!);
        if (await htmlFile.exists()) {
          final content = await htmlFile.readAsString();
          setState(() {
            _htmlContent = content;
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _error = 'HTML file not found';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading HTML: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.screenConfig.title),
          backgroundColor: currentTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            const ThemeSelector(),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתק',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.screenConfig.title),
          backgroundColor: currentTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            const ThemeSelector(),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתק',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadHtml(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_htmlContent == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.screenConfig.title),
          backgroundColor: currentTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            const ThemeSelector(),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתק',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: const Center(
          child: Text('No HTML content available'),
        ),
      );
    }

    final parser = HtmlParserService();
    final htmlWidget = parser.parseHtmlToWidget(
      _htmlContent!,
      assetsPath: widget.assetsPath,
      context: context,
    );

    final responsive = Responsive(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.screenConfig.title,
          style: TextStyle(
            fontSize: responsive.getFontSize(
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
        ),
        backgroundColor: currentTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSelector(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתק',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      backgroundColor: currentTheme.backgroundColor,
      body: ResponsiveContainer(
        maxWidth: responsive.isDesktop ? 1200 : null,
        child: SingleChildScrollView(
          child: htmlWidget,
        ),
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('התנתקות'),
        content: const Text('האם אתה בטוח שברצונך להתנתק?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('התנתקת בהצלחה')),
              );
            },
            child: const Text('התנתק'),
          ),
        ],
      ),
    );
  }
}

