import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io' if (dart.library.html) 'package:dynamic_ui_app/utils/web_stub.dart' as io;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../runtime/plugins/platform_plugins.dart';

/// Screen that renders HTML content directly using WebView
class HtmlScreen extends StatefulWidget {
  final String htmlPath;
  final String? assetsPath;
  final bool isRTL;

  const HtmlScreen({
    super.key,
    required this.htmlPath,
    this.assetsPath,
    this.isRTL = false,
  });

  @override
  State<HtmlScreen> createState() => _HtmlScreenState();
}

class _HtmlScreenState extends State<HtmlScreen> {
  bool _isLoading = true;
  String? _error;
  InAppWebViewController? _webViewController;
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    _loadHtmlContent();
  }

  Future<void> _loadHtmlContent() async {
    try {
      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _error = 'HTML loading not supported on web';
            _isLoading = false;
          });
        }
        return;
      }

      final file = io.File(widget.htmlPath);
      if (await file.exists()) {
        _htmlContent = await file.readAsString();
        debugPrint('Loaded HTML from: ${widget.htmlPath}');
        debugPrint('HTML content length: ${_htmlContent?.length}');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'HTML file not found: ${widget.htmlPath}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading HTML content: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading HTML: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _loadHtmlContent();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_htmlContent == null || _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get the directory of the HTML file as base URL
    final file = io.File(widget.htmlPath);
    final baseUrlString = file.parent.uri.toString();
    final baseUrl = WebUri(baseUrlString);

    return Scaffold(
      body: Directionality(
        textDirection: widget.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: InAppWebView(
          initialData: InAppWebViewInitialData(
            data: _htmlContent!,
            baseUrl: baseUrl,
            mimeType: 'text/html',
            encoding: 'utf-8',
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useShouldOverrideUrlLoading: true,
            useOnLoadResource: true,
            useHybridComposition: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _setupJavaScriptBridge(controller);
          },
          onLoadStart: (controller, url) {
            debugPrint('Page started loading: $url');
          },
          onLoadStop: (controller, url) async {
            debugPrint('Page finished loading: $url');
            // Inject JavaScript bridge after page loads
            await _injectJavaScriptBridge(controller);
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url?.toString() ?? '';
            debugPrint('Navigation request: $url');
            
            // Handle navigation to other HTML files
            if (url.endsWith('.html') || url.endsWith('.htm')) {
              if (widget.assetsPath != null) {
                final fileName = url.substring(url.lastIndexOf('/') + 1).split('\\').last;
                final newPath = '${widget.assetsPath}/$fileName';
                
                // Check if file exists
                final file = io.File(newPath);
                if (file.existsSync()) {
                  // Navigate to new HTML screen using Flutter navigation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HtmlScreen(
                            htmlPath: newPath,
                            assetsPath: widget.assetsPath,
                            isRTL: widget.isRTL,
                          ),
                        ),
                      );
                    }
                  });
                  return NavigationActionPolicy.CANCEL;
                }
              }
            }
            
            // Allow navigation for external URLs or same-origin resources
            return NavigationActionPolicy.ALLOW;
          },
          onLoadError: (controller, url, code, message) {
            debugPrint('WebView error: $message (code: $code)');
            if (mounted && code != -999) { // -999 is usually a cancelled request
              setState(() {
                _error = 'Error loading HTML: $message';
                _isLoading = false;
              });
            }
          },
          onReceivedError: (controller, request, error) {
            debugPrint('WebView received error: ${error.description}');
            if (mounted) {
              setState(() {
                _error = 'Error loading HTML: ${error.description}';
                _isLoading = false;
              });
            }
          },
        ),
      ),
    );
  }

  /// Setup JavaScript bridge to handle calls from HTML
  void _setupJavaScriptBridge(InAppWebViewController controller) {
    // Add JavaScript handler for FlutterApp calls
    controller.addJavaScriptHandler(
      handlerName: 'flutterApp',
      callback: (args) async {
        if (args.isEmpty) return null;
        
        final action = args[0] as String;
        debugPrint('JavaScript bridge called: $action');
        
        try {
          switch (action) {
            case 'checkLocationPermissionStatus':
              final result = await PlatformPlugins().checkLocationPermissionStatus();
              return jsonEncode(result);
              
            case 'checkCameraPermissionStatus':
              final result = await PlatformPlugins().checkCameraPermissionStatus();
              return jsonEncode(result);
              
            case 'checkStoragePermissionStatus':
              final result = await PlatformPlugins().checkStoragePermissionStatus();
              return jsonEncode(result);
              
            case 'checkContactsPermissionStatus':
              final result = await PlatformPlugins().checkContactsPermissionStatus();
              return jsonEncode(result);
              
            case 'checkNotificationPermissionStatus':
              final result = await PlatformPlugins().checkNotificationPermissionStatus();
              return jsonEncode(result);
              
            case 'requestLocationPermission':
              final result = await PlatformPlugins().requestLocationPermission();
              return jsonEncode(result);
              
            case 'requestCameraPermission':
              final result = await PlatformPlugins().requestCameraPermission();
              return jsonEncode(result);
              
            case 'requestStoragePermission':
              final result = await PlatformPlugins().requestStoragePermission();
              return jsonEncode(result);
              
            case 'requestContactsPermission':
            case 'getContacts':
              final result = await PlatformPlugins().getContacts();
              return jsonEncode(result);
              
            case 'pickImageFromGallery':
              final result = await PlatformPlugins().pickImageFromGallery();
              return jsonEncode(result);
              
            case 'takePicture':
              final result = await PlatformPlugins().takePicture();
              return jsonEncode(result);
              
            case 'requestNotificationPermission':
              final result = await PlatformPlugins().requestNotificationPermission();
              return jsonEncode(result);
              
            case 'sendNotification':
              if (args.length >= 3) {
                final title = args[1] as String;
                final body = args[2] as String;
                final result = await PlatformPlugins().sendNotification(title, body);
                return jsonEncode(result);
              }
              return jsonEncode({'success': false, 'message': 'Missing parameters'});
              
            case 'getStorageInfo':
              final result = await PlatformPlugins().getStorageInfo();
              return jsonEncode(result);
              
            case 'getNetworkStatus':
              final result = await PlatformPlugins().getNetworkStatus();
              return jsonEncode(result);
              
            case 'startSensors':
              final result = await PlatformPlugins().startSensors();
              return jsonEncode(result);
              
            case 'stopSensors':
              final result = await PlatformPlugins().stopSensors();
              return jsonEncode(result);
              
            case 'getSensorData':
              final result = await PlatformPlugins().getSensorData();
              return jsonEncode(result);
              
            default:
              return jsonEncode({'success': false, 'message': 'Unknown action: $action'});
          }
        } catch (e) {
          debugPrint('Error handling JavaScript bridge call: $e');
          return jsonEncode({'success': false, 'message': 'Error: $e'});
        }
      },
    );
  }

  /// Inject JavaScript bridge object into the page
  Future<void> _injectJavaScriptBridge(InAppWebViewController controller) async {
    const bridgeScript = '''
      (function() {
        if (window.FlutterApp) {
          return; // Already injected
        }
        
        window.FlutterApp = {
          call: function(action, ...args) {
            return new Promise((resolve, reject) => {
              window.flutter_inappwebview.callHandler('flutterApp', action, ...args)
                .then(function(result) {
                  try {
                    const parsed = typeof result === 'string' ? JSON.parse(result) : result;
                    resolve(parsed);
                  } catch (e) {
                    resolve(result);
                  }
                })
                .catch(function(error) {
                  reject(error);
                });
            });
          },
          
          checkLocationPermissionStatus: function() {
            return this.call('checkLocationPermissionStatus');
          },
          
          checkCameraPermissionStatus: function() {
            return this.call('checkCameraPermissionStatus');
          },
          
          checkStoragePermissionStatus: function() {
            return this.call('checkStoragePermissionStatus');
          },
          
          checkContactsPermissionStatus: function() {
            return this.call('checkContactsPermissionStatus');
          },
          
          checkNotificationPermissionStatus: function() {
            return this.call('checkNotificationPermissionStatus');
          },
          
          requestLocationPermission: function() {
            return this.call('requestLocationPermission');
          },
          
          requestCameraPermission: function() {
            return this.call('requestCameraPermission');
          },
          
          requestStoragePermission: function() {
            return this.call('requestStoragePermission');
          },
          
          requestContactsPermission: function() {
            return this.call('getContacts');
          },
          
          getContacts: function() {
            return this.call('getContacts');
          },
          
          pickImageFromGallery: function() {
            return this.call('pickImageFromGallery');
          },
          
          takePicture: function() {
            return this.call('takePicture');
          },
          
          requestNotificationPermission: function() {
            return this.call('requestNotificationPermission');
          },
          
          sendNotification: function(title, body) {
            return this.call('sendNotification', title, body);
          },
          
          getStorageInfo: function() {
            return this.call('getStorageInfo');
          },
          
          getNetworkStatus: function() {
            return this.call('getNetworkStatus');
          },
          
          startSensors: function() {
            return this.call('startSensors');
          },
          
          stopSensors: function() {
            return this.call('stopSensors');
          },
          
          getSensorData: function() {
            return this.call('getSensorData');
          }
        };
        
        console.log('FlutterApp bridge injected');
      })();
    ''';
    
    await controller.evaluateJavascript(source: bridgeScript);
  }
}
