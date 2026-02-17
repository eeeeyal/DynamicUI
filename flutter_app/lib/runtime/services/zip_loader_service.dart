import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Service to load and extract ZIP files for runtime
class ZipLoaderService {
  static const String _runtimeDirName = 'app_runtime';
  
  /// Load ZIP from local file path and extract to app_runtime directory
  /// Returns the path to the extracted directory
  Future<String> loadZip(String zipFilePath) async {
    try {
      final zipFile = File(zipFilePath);
      if (!await zipFile.exists()) {
        throw Exception('ZIP file not found: $zipFilePath');
      }

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final runtimeDir = Directory('${appDir.path}/$_runtimeDirName');
      
      // Clean existing runtime directory (overwrite)
      if (await runtimeDir.exists()) {
        await runtimeDir.delete(recursive: true);
      }
      await runtimeDir.create(recursive: true);

      // Read ZIP file
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Extract all files
      for (final file in archive) {
        final filePath = '${runtimeDir.path}/${file.name}';
        
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          // Create directory
          final dir = Directory(filePath);
          await dir.create(recursive: true);
        }
      }

      debugPrint('✅ ZIP extracted to: ${runtimeDir.path}');
      return runtimeDir.path;
    } catch (e) {
      throw Exception('Failed to load ZIP: $e');
    }
  }

  /// Get the runtime directory path
  Future<String?> getRuntimePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final runtimeDir = Directory('${appDir.path}/$_runtimeDirName');
    
    if (await runtimeDir.exists()) {
      return runtimeDir.path;
    }
    
    return null;
  }

  /// Check if runtime directory exists
  Future<bool> hasRuntime() async {
    final path = await getRuntimePath();
    return path != null;
  }

  /// Clear runtime directory
  Future<void> clearRuntime() async {
    final appDir = await getApplicationDocumentsDirectory();
    final runtimeDir = Directory('${appDir.path}/$_runtimeDirName');
    
    if (await runtimeDir.exists()) {
      await runtimeDir.delete(recursive: true);
    }
  }
}




