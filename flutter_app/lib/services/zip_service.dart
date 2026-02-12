import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZipService {
  static const String _configUrlKey = 'config_zip_url';
  static const String _lastVersionKey = 'last_config_version';
  static const String _configFileName = 'config.json';
  static const String _appConfigFileName = 'app.json';

  final Dio _dio = Dio();

  /// Detect file type (ZIP or GZ)
  bool _isGzFile(String filePath) {
    final lowerPath = filePath.toLowerCase();
    return lowerPath.endsWith('.gz') ||
        lowerPath.endsWith('.gzip') ||
        lowerPath.endsWith('.html.gz');
  }

  /// Download ZIP/GZ from server or use local file path
  Future<String> downloadZip(String zipUrlOrPath) async {
    try {
      // Check if it's a local file path
      if (zipUrlOrPath.startsWith('file://') || 
          zipUrlOrPath.startsWith('/') || 
          (zipUrlOrPath.length > 2 && zipUrlOrPath[1] == ':')) {
        // It's a local file path
        final file = File(zipUrlOrPath.replaceFirst('file://', ''));
        if (await file.exists()) {
          // Copy to app directory for consistency
          final appDir = await getApplicationDocumentsDirectory();
          final isGz = _isGzFile(zipUrlOrPath);
          final targetPath = isGz 
              ? '${appDir.path}/app-config.gz'
              : '${appDir.path}/app-config.zip';
          await file.copy(targetPath);
          return targetPath;
        } else {
          throw Exception('Local file not found: $zipUrlOrPath');
        }
      }

      // It's a URL - download it
      final appDir = await getApplicationDocumentsDirectory();
      final isGz = _isGzFile(zipUrlOrPath);
      final targetPath = isGz 
          ? '${appDir.path}/app-config.gz'
          : '${appDir.path}/app-config.zip';

      // Download ZIP/GZ file
      await _dio.download(
        zipUrlOrPath,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Download progress: $progress%');
          }
        },
      );

      return targetPath;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  /// Load ZIP/GZ from local file path (for development)
  Future<String> loadLocalZip(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      // Copy to app directory for consistency
      final appDir = await getApplicationDocumentsDirectory();
      final isGz = _isGzFile(filePath);
      final targetPath = isGz 
          ? '${appDir.path}/app-config.gz'
          : '${appDir.path}/app-config.zip';
      await file.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      throw Exception('Failed to load local file: $e');
    }
  }

  /// Extract ZIP/GZ file and return config.json content
  Future<Map<String, dynamic>> extractAndParseConfig(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      final isGz = _isGzFile(filePath);

      Map<String, dynamic>? configJson;
      final appDir = await getApplicationDocumentsDirectory();
      final extractDir = Directory('${appDir.path}/extracted');
      
      // Clean old extraction
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      if (isGz) {
        // Handle GZ file (single compressed file)
        try {
          // Decompress GZ
          final decompressed = GZipDecoder().decodeBytes(bytes);
          
          // Convert to string to check content type
          String content;
          try {
            content = utf8.decode(decompressed, allowMalformed: true);
          } catch (e) {
            // Try with different encoding
            content = String.fromCharCodes(decompressed);
          }
          
          final trimmedContent = content.trim();
          final lowerContent = trimmedContent.toLowerCase();
          
          // Try to parse as JSON directly (if GZ contains only config.json)
          try {
            configJson = _parseJson(trimmedContent);
            
            // Save the decompressed content as config.json
            final configFile = File('${extractDir.path}/$_configFileName');
            await configFile.writeAsBytes(decompressed);
            await _saveExtractedPath(extractDir.path);
            
            return configJson;
          } catch (e) {
            debugPrint('Not JSON, checking for HTML...');
          }
          
          // Check if it's HTML (more flexible detection)
          final isHtml = lowerContent.startsWith('<!doctype') ||
              lowerContent.startsWith('<html') ||
              lowerContent.contains('<html') ||
              lowerContent.contains('<!doctype') ||
              lowerContent.contains('<head>') ||
              lowerContent.contains('<body>') ||
              lowerContent.contains('<script') ||
              (lowerContent.contains('<') && lowerContent.contains('>') && 
               lowerContent.length > 100); // Likely HTML if has tags and is long
          
            if (isHtml) {
              debugPrint('Detected HTML content, extracting config...');
              
              // Save HTML file for parsing
              final savedHtmlFile = File('${extractDir.path}/index.html');
              await savedHtmlFile.writeAsBytes(decompressed);
              debugPrint('Saved HTML to: ${savedHtmlFile.path}');
              
              // Try to extract config from HTML first
              configJson = _extractConfigFromHtml(content);
              
              if (configJson != null) {
                debugPrint('Successfully extracted config from HTML');
                // Save the config
                final configFile = File('${extractDir.path}/$_configFileName');
                await configFile.writeAsString(
                  jsonEncode(configJson),
                  encoding: utf8,
                );
                
                await _saveExtractedPath(extractDir.path);
                return configJson;
              } else {
                debugPrint('No config found in HTML - will parse HTML directly');
                // Create a config structure from HTML
                // This allows the app to render HTML directly
                configJson = {
                  'version': '1.0.0',
                  'screens': [
                    {
                      'id': 'html_content',
                      'type': 'html',
                      'title': 'HTML Content',
                      'htmlPath': '${extractDir.path}/index.html',
                    }
                  ],
                  'theme': {
                    'primaryColor': '#1976D2',
                    'secondaryColor': '#424242',
                    'backgroundColor': '#FFFFFF',
                  }
                };
                
                // Save the config
                final configFile = File('${extractDir.path}/$_configFileName');
                await configFile.writeAsString(
                  jsonEncode(configJson),
                  encoding: utf8,
                );
                
                await _saveExtractedPath(extractDir.path);
                return configJson;
              }
            }
          
          // If not HTML, try to extract as TAR.GZ
          try {
            debugPrint('Trying TAR.GZ format...');
            final tarArchive = TarDecoder().decodeBytes(decompressed);
            
            for (final file in tarArchive) {
              final filename = file.name;
              final outPath = '${extractDir.path}/$filename';

              if (file.isFile) {
                final outFile = File(outPath);
                await outFile.create(recursive: true);
                await outFile.writeAsBytes(file.content);

                if (filename == _configFileName || 
                    filename.endsWith('/$_configFileName') ||
                    filename.endsWith('\\$_configFileName')) {
                  final fileContent = String.fromCharCodes(file.content);
                  configJson = _parseJson(fileContent);
                }
              } else {
                await Directory(outPath).create(recursive: true);
              }
            }
            
            if (configJson != null) {
              await _saveExtractedPath(extractDir.path);
              return configJson;
            }
          } catch (tarError) {
            debugPrint('TAR.GZ parsing failed: $tarError');
          }
          
          // If we got here, nothing worked
          throw Exception(
            'Failed to parse GZ file. Content type: ${isHtml ? "HTML" : "Unknown"}. '
            'Tried: JSON, HTML extraction, TAR.GZ. Content preview: ${trimmedContent.substring(0, trimmedContent.length > 200 ? 200 : trimmedContent.length)}'
          );
        } catch (e) {
          throw Exception('Failed to decompress GZ file: $e');
        }
      } else {
        // Handle ZIP file
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Check if ZIP contains HTML files
        bool hasHtmlFiles = false;
        List<String> htmlFiles = [];
        
        for (final file in archive) {
          final filename = file.name.toLowerCase();
          if (filename.endsWith('.html') || filename.endsWith('.htm')) {
            hasHtmlFiles = true;
            htmlFiles.add(file.name);
          }
        }
        
        // If ZIP contains HTML files, create config for HTML screens
        if (hasHtmlFiles && htmlFiles.isNotEmpty) {
          debugPrint('📄 Found ${htmlFiles.length} HTML files in ZIP');
          
          // Extract all files
          for (final file in archive) {
            final filename = file.name;
            final outPath = '${extractDir.path}/$filename';

            if (file.isFile) {
              final outFile = File(outPath);
              await outFile.create(recursive: true);
              await outFile.writeAsBytes(file.content);
            } else {
              await Directory(outPath).create(recursive: true);
            }
          }
          
          // Create config with HTML screens
          final screens = htmlFiles.map((htmlFile) {
            // Extract screen name from path (handle subdirectories)
            final fileName = htmlFile.split('/').last.split('\\').last;
            final screenName = fileName.replaceAll('.html', '').replaceAll('.htm', '');
            return {
              'id': screenName,
              'type': 'html',
              'title': screenName,
              'htmlPath': htmlFile, // Keep full path including subdirectory
            };
          }).toList();
          
          configJson = {
            'version': '1.0.0',
            'screens': screens,
            'theme': {
              'primaryColor': '#1976D2',
              'secondaryColor': '#424242',
              'backgroundColor': '#FFFFFF',
            }
          };
          
          debugPrint('✅ Created config with ${screens.length} HTML screens');
          await _saveExtractedPath(extractDir.path);
        } else {
          // Normal ZIP extraction
          // Extract all files
          for (final file in archive) {
            final filename = file.name;
            final outPath = '${extractDir.path}/$filename';

            if (file.isFile) {
              final outFile = File(outPath);
              await outFile.create(recursive: true);
              await outFile.writeAsBytes(file.content);

              // Find and parse config.json or app.json (check root or any subdirectory)
              if (filename == _configFileName || 
                  filename.endsWith('/$_configFileName') ||
                  filename.endsWith('\\$_configFileName') ||
                  filename == _appConfigFileName ||
                  filename.endsWith('/$_appConfigFileName') ||
                  filename.endsWith('\\$_appConfigFileName')) {
                final content = String.fromCharCodes(file.content);
                configJson = _parseJson(content);
              }
            } else {
              // Create directory
              await Directory(outPath).create(recursive: true);
            }
          }
        }
      }

      // If configJson is null but we have HTML files, that's OK - we'll use HTML screens
      if (configJson == null) {
        // Check again if we have HTML files (for the error message)
        bool hasHtml = false;
        if (!isGz) {
          final archive = ZipDecoder().decodeBytes(bytes);
          for (final file in archive) {
            final filename = file.name.toLowerCase();
            if (filename.endsWith('.html') || filename.endsWith('.htm')) {
              hasHtml = true;
              break;
            }
          }
        }
        
        if (!hasHtml) {
          throw Exception('config.json or app.json not found in ${isGz ? "GZ" : "ZIP"} file');
        }
      }

      // Find the actual root directory (could be a subdirectory if ZIP contains a folder)
      String actualExtractedPath = extractDir.path;
      
      // Check if there's a single subdirectory that contains app.json or config.json
      try {
        final dir = Directory(extractDir.path);
        final subdirs = <Directory>[];
        await for (final entity in dir.list(recursive: false)) {
          if (entity is Directory) {
            subdirs.add(entity);
          }
        }
        
        // If there's exactly one subdirectory, use it as the root
        if (subdirs.length == 1) {
          final subdir = subdirs.first;
          final appJsonFile = File('${subdir.path}/app.json');
          final configJsonFile = File('${subdir.path}/config.json');
          if (await appJsonFile.exists() || await configJsonFile.exists()) {
            actualExtractedPath = subdir.path;
            debugPrint('✅ Using subdirectory as root: $actualExtractedPath');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error checking subdirectories: $e');
      }
      
      // Ensure configJson is not null
      if (configJson == null) {
        throw Exception('Failed to extract config from ${isGz ? "GZ" : "ZIP"} file');
      }
      
      // Save extracted assets path for later use
      await _saveExtractedPath(actualExtractedPath);
      debugPrint('✅ Saved extracted path: $actualExtractedPath');
      debugPrint('📁 Listing extracted files:');
      try {
        final dir = Directory(actualExtractedPath);
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            debugPrint('  📄 ${entity.path.replaceAll(actualExtractedPath, '')}');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error listing files: $e');
      }

      return configJson;
    } catch (e) {
      throw Exception('Failed to extract file: $e');
    }
  }

  /// Download JSON config separately (Format 2)
  Future<Map<String, dynamic>> downloadJsonConfig(String jsonUrl) async {
    try {
      debugPrint('Downloading JSON config from: $jsonUrl');
      
      // Check if it's a local file
      if (jsonUrl.startsWith('file://') || 
          jsonUrl.startsWith('/') || 
          (jsonUrl.length > 2 && jsonUrl[1] == ':')) {
        final file = File(jsonUrl.replaceFirst('file://', ''));
        if (await file.exists()) {
          final content = await file.readAsString();
          return _parseJson(content);
        } else {
          throw Exception('Local JSON file not found: $jsonUrl');
        }
      }
      
      // Download from URL
      final response = await _dio.get(jsonUrl);
      if (response.statusCode == 200) {
        return _parseJson(response.data.toString());
      } else {
        throw Exception('Failed to download JSON config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download JSON config: $e');
    }
  }

  /// Extract only assets from ZIP (without looking for config.json)
  Future<void> extractAssets(String zipPath) async {
    try {
      final file = File(zipPath);
      if (!await file.exists()) {
        throw Exception('ZIP file not found: $zipPath');
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final appDir = await getApplicationDocumentsDirectory();
      final extractDir = Directory('${appDir.path}/extracted');
      
      // Clean old extraction
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // Extract all files except config.json
      for (final file in archive) {
        final filename = file.name;
        
        // Skip config.json - it's loaded separately
        if (filename == _configFileName || 
            filename.endsWith('/$_configFileName') ||
            filename.endsWith('\\$_configFileName')) {
          continue;
        }
        
        final outPath = '${extractDir.path}/$filename';

        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content);
        } else {
          await Directory(outPath).create(recursive: true);
        }
      }
      
      await _saveExtractedPath(extractDir.path);
      debugPrint('Assets extracted to: ${extractDir.path}');
    } catch (e) {
      throw Exception('Failed to extract assets: $e');
    }
  }

  /// Parse JSON string to Map
  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse JSON: $e');
    }
  }

  /// Extract config from HTML file
  /// Looks for config in: <script> tags, data attributes, or embedded JSON
  Map<String, dynamic>? _extractConfigFromHtml(String htmlContent) {
    try {
      debugPrint('Extracting config from HTML, content length: ${htmlContent.length}');
      // Method 1: Look for <script type="application/json" id="app-config">
      final scriptIdPattern = RegExp(
        '<script[^>]*id=["\']app-config["\'][^>]*type=["\']application/json["\'][^>]*>(.*?)</script>',
        caseSensitive: false,
        dotAll: true,
      );
      var match = scriptIdPattern.firstMatch(htmlContent);
      if (match != null) {
        final jsonStr = match.group(1)?.trim();
        if (jsonStr != null && jsonStr.isNotEmpty) {
          return _parseJson(jsonStr);
        }
      }

      // Method 2: Look for <script>window.appConfig = {...}</script>
      final scriptVarPattern = RegExp(
        r'<script[^>]*>.*?window\.appConfig\s*=\s*(\{.*?\});',
        caseSensitive: false,
        dotAll: true,
      );
      match = scriptVarPattern.firstMatch(htmlContent);
      if (match != null) {
        final jsonStr = match.group(1)?.trim();
        if (jsonStr != null && jsonStr.isNotEmpty) {
          return _parseJson(jsonStr);
        }
      }

      // Method 3: Look for data-config attribute
      final dataConfigPattern = RegExp(
        'data-config=(["\'])([^"\']+)\\1',
        caseSensitive: false,
      );
      match = dataConfigPattern.firstMatch(htmlContent);
      if (match != null) {
        final jsonStr = match.group(2);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          // Decode HTML entities if needed
          final decoded = jsonStr
              .replaceAll('&quot;', '"')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>');
          return _parseJson(decoded);
        }
      }

      // Method 4: Look for JSON in any <script> tag (more flexible)
      debugPrint('Searching for JSON in script tags...');
      final scriptPattern = RegExp(
        r'<script[^>]*>(.*?)</script>',
        caseSensitive: false,
        dotAll: true,
      );
      final scriptMatches = scriptPattern.allMatches(htmlContent);
      int scriptIndex = 0;
      for (final scriptMatch in scriptMatches) {
        scriptIndex++;
        final scriptContent = scriptMatch.group(1)?.trim() ?? '';
        debugPrint('Script $scriptIndex: length=${scriptContent.length}');
        
        // Skip if it's clearly JavaScript code (contains common JS keywords)
        final isJavaScript = scriptContent.contains('function') ||
            scriptContent.contains('const ') ||
            scriptContent.contains('let ') ||
            scriptContent.contains('var ') ||
            scriptContent.contains('class ') ||
            scriptContent.contains('constructor') ||
            scriptContent.contains('this.') ||
            scriptContent.contains('use strict') ||
            scriptContent.contains('=>') ||
            scriptContent.contains('import ') ||
            scriptContent.contains('export ');
        
        if (isJavaScript) {
          debugPrint('Script $scriptIndex is JavaScript code, skipping...');
          
          // But check if there's a JSON string inside the JavaScript
          // Look for patterns like: const config = {...} or window.config = {...}
          debugPrint('Searching for config in JavaScript code...');
          
          // Method 1: Look for config variables
          final jsConfigPatterns = [
            RegExp(r'(?:const|let|var)\s+\w*config\w*\s*=\s*(\{.*?\});', caseSensitive: false, dotAll: true),
            RegExp(r'window\.\w*config\w*\s*=\s*(\{.*?\});', caseSensitive: false, dotAll: true),
            RegExp(r'appConfig\s*[:=]\s*(\{.*?\})', caseSensitive: false, dotAll: true),
            RegExp(r'config\s*[:=]\s*(\{.*?\})', caseSensitive: false, dotAll: true),
          ];
          
          for (final pattern in jsConfigPatterns) {
            final match = pattern.firstMatch(scriptContent);
            if (match != null) {
              final jsonStr = match.group(1)?.trim();
              if (jsonStr != null && jsonStr.length > 50) {
                try {
                  debugPrint('Found potential config in JavaScript variable, trying to parse...');
                  final parsed = _parseJson(jsonStr);
                  if (parsed.containsKey('version') || parsed.containsKey('screens') || parsed.containsKey('theme')) {
                    debugPrint('Found valid config structure in JavaScript variable');
                    return parsed;
                  }
                } catch (e) {
                  debugPrint('Failed to parse config from JavaScript variable: $e');
                }
              }
            }
          }
          
          // Method 2: Look for objects that contain "screens" or "version" keywords
          // This is more aggressive - find any object that looks like our config
          debugPrint('Searching for objects containing "screens" or "version" in JavaScript...');
          if (scriptContent.contains('screens') || scriptContent.contains('version') || scriptContent.contains('theme')) {
            // Find all JSON-like objects in the script
            int braceCount = 0;
            int startIndex = -1;
            for (int i = 0; i < scriptContent.length; i++) {
              if (scriptContent[i] == '{') {
                if (startIndex == -1) startIndex = i;
                braceCount++;
              } else if (scriptContent[i] == '}') {
                braceCount--;
                if (braceCount == 0 && startIndex != -1) {
                  // Found a complete object
                  final jsonStr = scriptContent.substring(startIndex, i + 1);
                  if (jsonStr.length > 50 && 
                      (jsonStr.contains('"screens"') || jsonStr.contains("'screens'") ||
                       jsonStr.contains('"version"') || jsonStr.contains("'version'") ||
                       jsonStr.contains('"theme"') || jsonStr.contains("'theme'"))) {
                    try {
                      debugPrint('Found object with config keywords, trying to parse...');
                      final parsed = _parseJson(jsonStr);
                      if (parsed.containsKey('version') || parsed.containsKey('screens') || parsed.containsKey('theme')) {
                        debugPrint('Found valid config structure in JavaScript object');
                        return parsed;
                      }
                    } catch (e) {
                      debugPrint('Failed to parse object: $e');
                    }
                  }
                  startIndex = -1;
                }
              }
            }
          }
          continue;
        }
        
        // Check if it looks like JSON (more flexible - find JSON object)
        if (scriptContent.contains('{') && scriptContent.contains('}')) {
          // Try to find complete JSON objects by matching balanced braces
          int braceCount = 0;
          int startIndex = -1;
          for (int i = 0; i < scriptContent.length; i++) {
            if (scriptContent[i] == '{') {
              if (startIndex == -1) startIndex = i;
              braceCount++;
            } else if (scriptContent[i] == '}') {
              braceCount--;
              if (braceCount == 0 && startIndex != -1) {
                // Found a complete JSON object
                final jsonStr = scriptContent.substring(startIndex, i + 1);
                if (jsonStr.length > 50) { // Minimum size for config
                  try {
                    debugPrint('Trying to parse JSON from script $scriptIndex, length=${jsonStr.length}');
                    final parsed = _parseJson(jsonStr);
                    // Check if it looks like our config structure
                    if (parsed.containsKey('version') || parsed.containsKey('screens') || parsed.containsKey('theme')) {
                      debugPrint('Found valid config structure in script $scriptIndex');
                      return parsed;
                    }
                  } catch (e) {
                    debugPrint('Failed to parse JSON from script $scriptIndex: $e');
                    // Continue to next match
                  }
                }
                startIndex = -1;
              }
            }
          }
        }
      }

      // Method 5: Look for JSON in comments <!-- config: {...} -->
      final commentPattern = RegExp(
        r'<!--\s*config:\s*(\{.*?\})\s*-->',
        caseSensitive: false,
        dotAll: true,
      );
      match = commentPattern.firstMatch(htmlContent);
      if (match != null) {
        final jsonStr = match.group(1)?.trim();
        if (jsonStr != null && jsonStr.isNotEmpty) {
          debugPrint('Found config in HTML comment');
          return _parseJson(jsonStr);
        }
      }

      // Method 6: Look for JSON in data attributes or meta tags
      debugPrint('Trying to find config in data attributes or meta tags...');
      final dataPatterns = [
        RegExp('data-app-config=(["\'])([^"\']+)\\1', caseSensitive: false),
        RegExp('data-config=(["\'])([^"\']+)\\1', caseSensitive: false),
        RegExp('<meta[^>]*name=["\']app-config["\'][^>]*content=(["\'])([^"\']+)\\1', caseSensitive: false),
      ];
      
      for (final pattern in dataPatterns) {
        final match = pattern.firstMatch(htmlContent);
        if (match != null) {
          final jsonStr = match.group(2); // Group 2 is the content
          if (jsonStr != null && jsonStr.isNotEmpty) {
            try {
              // Decode HTML entities
              final decoded = jsonStr
                  .replaceAll('&quot;', '"')
                  .replaceAll('&amp;', '&')
                  .replaceAll('&lt;', '<')
                  .replaceAll('&gt;', '>');
              final parsed = _parseJson(decoded);
              if (parsed.containsKey('version') || parsed.containsKey('screens') || parsed.containsKey('theme')) {
                debugPrint('Found config in data attribute/meta tag');
                return parsed;
              }
            } catch (e) {
              debugPrint('Failed to parse config from data attribute: $e');
            }
          }
        }
      }

      // Method 7: Look for JSON anywhere in the HTML (last resort, but skip script tags)
      debugPrint('Trying to find JSON anywhere in HTML (excluding script tags)...');
      // Remove script tags first to avoid JavaScript code
      final htmlWithoutScripts = htmlContent.replaceAll(
        RegExp('<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
        '',
      );
      
      // Find all potential JSON objects by matching balanced braces
      int braceCount = 0;
      int startIndex = -1;
      for (int i = 0; i < htmlWithoutScripts.length; i++) {
        if (htmlWithoutScripts[i] == '{') {
          if (startIndex == -1) startIndex = i;
          braceCount++;
        } else if (htmlWithoutScripts[i] == '}') {
          braceCount--;
          if (braceCount == 0 && startIndex != -1) {
            // Found a complete JSON object
            final jsonStr = htmlWithoutScripts.substring(startIndex, i + 1);
            if (jsonStr.length > 50) { // Minimum size for config
              try {
                final parsed = _parseJson(jsonStr);
                // Check if it looks like our config structure
                if (parsed.containsKey('version') || parsed.containsKey('screens') || parsed.containsKey('theme')) {
                  debugPrint('Found config structure in HTML (outside script tags)');
                  return parsed;
                }
              } catch (e) {
                // Not valid JSON, continue
              }
            }
            startIndex = -1;
          }
        }
      }

      debugPrint('No config found in HTML');
      return null;
    } catch (e) {
      debugPrint('Error extracting config from HTML: $e');
      return null;
    }
  }

  /// Get path to extracted assets
  Future<String?> getExtractedAssetsPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('extracted_assets_path');
  }

  /// Save extracted assets path
  Future<void> _saveExtractedPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extracted_assets_path', path);
  }

  /// Save extracted assets path (public method)
  Future<void> saveExtractedPath(String path) async {
    await _saveExtractedPath(path);
  }

  /// Save config URL
  Future<void> saveConfigUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configUrlKey, url);
  }

  /// Get saved config URL
  Future<String?> getConfigUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_configUrlKey);
  }

  /// Save last version
  Future<void> saveLastVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastVersionKey, version);
  }

  /// Get last version
  Future<String?> getLastVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastVersionKey);
  }

  /// Check if update is needed
  Future<bool> needsUpdate(String currentVersion) async {
    final lastVersion = await getLastVersion();
    return lastVersion != currentVersion;
  }
}

