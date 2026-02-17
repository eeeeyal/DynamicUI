import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// flutter_local_notifications removed due to Windows build issues
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Platform plugins handler for native device features
class PlatformPlugins {
  static final PlatformPlugins _instance = PlatformPlugins._internal();
  factory PlatformPlugins() => _instance;
  PlatformPlugins._internal();

  final ImagePicker _imagePicker = ImagePicker();
  // FlutterLocalNotificationsPlugin removed due to Windows build issues

  /// Check location permission status
  Future<Map<String, dynamic>?> checkLocationPermissionStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      
      String status = 'לא נבדק';
      bool isGranted = false;
      
      if (!serviceEnabled) {
        status = 'שירותי מיקום כבויים';
        isGranted = false;
      } else {
        switch (permission) {
          case LocationPermission.denied:
            status = 'הרשאה נדחתה';
            isGranted = false;
            break;
          case LocationPermission.deniedForever:
            status = 'הרשאה נדחתה לצמיתות';
            isGranted = false;
            break;
          case LocationPermission.whileInUse:
            status = 'הרשאה ניתנה (בשימוש)';
            isGranted = true;
            break;
          case LocationPermission.always:
            status = 'הרשאה ניתנה (תמיד)';
            isGranted = true;
            break;
          default:
            status = 'לא נבדק';
            isGranted = false;
        }
      }
      
      return {
        'success': true,
        'status': status,
        'isGranted': isGranted,
        'serviceEnabled': serviceEnabled,
        'permission': permission.toString(),
      };
    } catch (e) {
      debugPrint('Location permission check error: $e');
      final errorMessage = e.toString();
      
      // Check if it's a manifest permission error
      if (errorMessage.contains('manifest') || errorMessage.contains('ACCESS_FINE_LOCATION') || errorMessage.contains('ACCESS_COARSE_LOCATION')) {
        return {
          'success': false,
          'status': 'הרשאות לא מוגדרות ב-Manifest',
          'isGranted': false,
          'message': 'אנא הוסף הרשאות מיקום ל-AndroidManifest.xml',
          'error': errorMessage,
        };
      }
      
      return {
        'success': false,
        'status': 'שגיאה בבדיקה',
        'isGranted': false,
        'message': 'שגיאה בבדיקת הרשאות מיקום: $e',
        'error': errorMessage,
      };
    }
  }

  /// Request location permission and get current position
  Future<Map<String, dynamic>?> requestLocationPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'message': 'שירותי מיקום כבויים. אנא הפעל את שירותי המיקום בהגדרות המכשיר.',
          'needsSettings': true,
        };
      }
      
      // Request permission (this will show the dialog if needed)
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        return {
          'success': false,
          'message': 'הרשאות מיקום נדחו. אנא אפשר גישה למיקום בהגדרות האפליקציה.',
          'permissionStatus': 'denied',
        };
      }
      
      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'message': 'הרשאות מיקום נדחו לצמיתות. אנא אפשר גישה למיקום בהגדרות האפליקציה.',
          'permissionStatus': 'deniedForever',
          'needsSettings': true,
        };
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'permissionStatus': 'granted',
      };
    } catch (e) {
      debugPrint('Location error: $e');
      return {
        'success': false,
        'message': 'שגיאה בקבלת מיקום: $e'
      };
    }
  }

  /// Check camera permission status
  Future<Map<String, dynamic>?> checkCameraPermissionStatus() async {
    try {
      PermissionStatus status = await Permission.camera.status;
      
      String statusText = 'לא נבדק';
      bool isGranted = false;
      
      switch (status) {
        case PermissionStatus.granted:
          statusText = 'הרשאה ניתנה';
          isGranted = true;
          break;
        case PermissionStatus.denied:
          statusText = 'הרשאה נדחתה';
          isGranted = false;
          break;
        case PermissionStatus.restricted:
          statusText = 'הרשאה מוגבלת';
          isGranted = false;
          break;
        case PermissionStatus.limited:
          statusText = 'הרשאה מוגבלת';
          isGranted = true;
          break;
        case PermissionStatus.permanentlyDenied:
          statusText = 'הרשאה נדחתה לצמיתות';
          isGranted = false;
          break;
        default:
          statusText = 'לא נבדק';
          isGranted = false;
      }
      
      return {
        'success': true,
        'status': statusText,
        'isGranted': isGranted,
        'permission': status.toString(),
      };
    } catch (e) {
      debugPrint('Camera permission check error: $e');
      return {
        'success': false,
        'status': 'שגיאה בבדיקה',
        'isGranted': false,
        'message': 'שגיאה בבדיקת הרשאות מצלמה: $e',
      };
    }
  }

  /// Check storage/photos permission status
  Future<Map<String, dynamic>?> checkStoragePermissionStatus() async {
    try {
      PermissionStatus status = await Permission.photos.status;
      
      String statusText = 'לא נבדק';
      bool isGranted = false;
      
      switch (status) {
        case PermissionStatus.granted:
          statusText = 'הרשאה ניתנה';
          isGranted = true;
          break;
        case PermissionStatus.denied:
          statusText = 'הרשאה נדחתה';
          isGranted = false;
          break;
        case PermissionStatus.restricted:
          statusText = 'הרשאה מוגבלת';
          isGranted = false;
          break;
        case PermissionStatus.limited:
          statusText = 'הרשאה מוגבלת';
          isGranted = true;
          break;
        case PermissionStatus.permanentlyDenied:
          statusText = 'הרשאה נדחתה לצמיתות';
          isGranted = false;
          break;
        default:
          statusText = 'לא נבדק';
          isGranted = false;
      }
      
      return {
        'success': true,
        'status': statusText,
        'isGranted': isGranted,
        'permission': status.toString(),
      };
    } catch (e) {
      debugPrint('Storage permission check error: $e');
      return {
        'success': false,
        'status': 'שגיאה בבדיקה',
        'isGranted': false,
        'message': 'שגיאה בבדיקת הרשאות אחסון: $e',
      };
    }
  }

  /// Check contacts permission status
  Future<Map<String, dynamic>?> checkContactsPermissionStatus() async {
    try {
      PermissionStatus status = await Permission.contacts.status;
      
      String statusText = 'לא נבדק';
      bool isGranted = false;
      
      switch (status) {
        case PermissionStatus.granted:
          statusText = 'הרשאה ניתנה';
          isGranted = true;
          break;
        case PermissionStatus.denied:
          statusText = 'הרשאה נדחתה';
          isGranted = false;
          break;
        case PermissionStatus.restricted:
          statusText = 'הרשאה מוגבלת';
          isGranted = false;
          break;
        case PermissionStatus.limited:
          statusText = 'הרשאה מוגבלת';
          isGranted = true;
          break;
        case PermissionStatus.permanentlyDenied:
          statusText = 'הרשאה נדחתה לצמיתות';
          isGranted = false;
          break;
        default:
          statusText = 'לא נבדק';
          isGranted = false;
      }
      
      return {
        'success': true,
        'status': statusText,
        'isGranted': isGranted,
        'permission': status.toString(),
      };
    } catch (e) {
      debugPrint('Contacts permission check error: $e');
      return {
        'success': false,
        'status': 'שגיאה בבדיקה',
        'isGranted': false,
        'message': 'שגיאה בבדיקת הרשאות אנשי קשר: $e',
      };
    }
  }

  /// Check notification permission status
  Future<Map<String, dynamic>?> checkNotificationPermissionStatus() async {
    try {
      PermissionStatus status = await Permission.notification.status;
      
      String statusText = 'לא נבדק';
      bool isGranted = false;
      
      switch (status) {
        case PermissionStatus.granted:
          statusText = 'הרשאה ניתנה';
          isGranted = true;
          break;
        case PermissionStatus.denied:
          statusText = 'הרשאה נדחתה';
          isGranted = false;
          break;
        case PermissionStatus.restricted:
          statusText = 'הרשאה מוגבלת';
          isGranted = false;
          break;
        case PermissionStatus.limited:
          statusText = 'הרשאה מוגבלת';
          isGranted = true;
          break;
        case PermissionStatus.permanentlyDenied:
          statusText = 'הרשאה נדחתה לצמיתות';
          isGranted = false;
          break;
        default:
          statusText = 'לא נבדק';
          isGranted = false;
      }
      
      return {
        'success': true,
        'status': statusText,
        'isGranted': isGranted,
        'permission': status.toString(),
      };
    } catch (e) {
      debugPrint('Notification permission check error: $e');
      return {
        'success': false,
        'status': 'שגיאה בבדיקה',
        'isGranted': false,
        'message': 'שגיאה בבדיקת הרשאות התראות: $e',
      };
    }
  }

  /// Request image permission and pick image from gallery
  Future<Map<String, dynamic>?> pickImageFromGallery() async {
    try {
      // Request permission
      PermissionStatus status = await Permission.photos.request();
      
      if (!status.isGranted) {
        return {
          'success': false,
          'message': 'הרשאות גישה לתמונות נדחו'
        };
      }
      
      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image == null) {
        return {
          'success': false,
          'message': 'לא נבחרה תמונה'
        };
      }
      
      return {
        'success': true,
        'path': image.path,
        'name': image.name,
        'size': await image.length(),
      };
    } catch (e) {
      debugPrint('Image picker error: $e');
      return {
        'success': false,
        'message': 'שגיאה בבחירת תמונה: $e'
      };
    }
  }

  /// Request camera permission (without taking picture)
  Future<Map<String, dynamic>?> requestCameraPermission() async {
    try {
      PermissionStatus status = await Permission.camera.request();
      
      String statusText = 'לא נבדק';
      bool isGranted = false;
      
      switch (status) {
        case PermissionStatus.granted:
          statusText = 'הרשאה ניתנה';
          isGranted = true;
          break;
        case PermissionStatus.denied:
          statusText = 'הרשאה נדחתה';
          isGranted = false;
          break;
        case PermissionStatus.restricted:
          statusText = 'הרשאה מוגבלת';
          isGranted = false;
          break;
        case PermissionStatus.limited:
          statusText = 'הרשאה מוגבלת';
          isGranted = true;
          break;
        case PermissionStatus.permanentlyDenied:
          statusText = 'הרשאה נדחתה לצמיתות';
          isGranted = false;
          break;
        default:
          statusText = 'לא נבדק';
          isGranted = false;
      }
      
      return {
        'success': isGranted,
        'status': statusText,
        'isGranted': isGranted,
        'message': isGranted ? 'הרשאות מצלמה אושרו' : 'הרשאות מצלמה נדחו',
        'permission': status.toString(),
      };
    } catch (e) {
      debugPrint('Camera permission request error: $e');
      return {
        'success': false,
        'status': 'שגיאה',
        'isGranted': false,
        'message': 'שגיאה בבקשת הרשאות מצלמה: $e',
      };
    }
  }

  /// Request storage/photos permission (without picking image)
  Future<Map<String, dynamic>?> requestStoragePermission() async {
    try {
      PermissionStatus status = await Permission.photos.request();
      
      String statusText = 'לא נבדק';
      bool isGranted = false;
      
      switch (status) {
        case PermissionStatus.granted:
          statusText = 'הרשאה ניתנה';
          isGranted = true;
          break;
        case PermissionStatus.denied:
          statusText = 'הרשאה נדחתה';
          isGranted = false;
          break;
        case PermissionStatus.restricted:
          statusText = 'הרשאה מוגבלת';
          isGranted = false;
          break;
        case PermissionStatus.limited:
          statusText = 'הרשאה מוגבלת';
          isGranted = true;
          break;
        case PermissionStatus.permanentlyDenied:
          statusText = 'הרשאה נדחתה לצמיתות';
          isGranted = false;
          break;
        default:
          statusText = 'לא נבדק';
          isGranted = false;
      }
      
      return {
        'success': isGranted,
        'status': statusText,
        'isGranted': isGranted,
        'message': isGranted ? 'הרשאות אחסון אושרו' : 'הרשאות אחסון נדחו',
        'permission': status.toString(),
      };
    } catch (e) {
      debugPrint('Storage permission request error: $e');
      return {
        'success': false,
        'status': 'שגיאה',
        'isGranted': false,
        'message': 'שגיאה בבקשת הרשאות אחסון: $e',
      };
    }
  }

  /// Request camera permission and take picture
  Future<Map<String, dynamic>?> takePicture() async {
    try {
      // Request permission
      PermissionStatus status = await Permission.camera.request();
      
      if (!status.isGranted) {
        return {
          'success': false,
          'message': 'הרשאות מצלמה נדחו'
        };
      }
      
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return {
          'success': false,
          'message': 'לא נמצאה מצלמה'
        };
      }
      
      // Pick image from camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      
      if (image == null) {
        return {
          'success': false,
          'message': 'לא נלקחה תמונה'
        };
      }
      
      return {
        'success': true,
        'path': image.path,
        'name': image.name,
        'size': await image.length(),
      };
    } catch (e) {
      debugPrint('Camera error: $e');
      return {
        'success': false,
        'message': 'שגיאה בצילום: $e'
      };
    }
  }

  /// Request contacts permission and get contacts
  /// Uses flutter_contacts plugin which is compatible with AGP 8.1+
  Future<Map<String, dynamic>?> getContacts() async {
    try {
      // Request permission
      PermissionStatus status = await Permission.contacts.request();
      
      if (!status.isGranted) {
        return {
          'success': false,
          'message': 'הרשאות אנשי קשר נדחו'
        };
      }
      
      // Check if contacts permission is granted using flutter_contacts
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        return {
          'success': false,
          'message': 'הרשאות אנשי קשר נדחו'
        };
      }
      
      // Get contacts using flutter_contacts
      List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );
      
      List<Map<String, dynamic>> contactsList = contacts.map((contact) {
        return {
          'name': contact.displayName,
          'phones': contact.phones.map((p) => p.number).toList(),
          'emails': contact.emails.map((e) => e.address).toList(),
        };
      }).toList();
      
      return {
        'success': true,
        'contacts': contactsList,
        'count': contactsList.length,
      };
    } catch (e) {
      debugPrint('Contacts error: $e');
      return {
        'success': false,
        'message': 'שגיאה בקבלת אנשי קשר: $e'
      };
    }
  }

  /// Request notification permission (without sending notification)
  Future<Map<String, dynamic>?> requestNotificationPermission() async {
    try {
      PermissionStatus status = await Permission.notification.request();
      
      String statusText = 'לא נבדק';
      bool isGranted = false;
      
      switch (status) {
        case PermissionStatus.granted:
          statusText = 'הרשאה ניתנה';
          isGranted = true;
          break;
        case PermissionStatus.denied:
          statusText = 'הרשאה נדחתה';
          isGranted = false;
          break;
        case PermissionStatus.restricted:
          statusText = 'הרשאה מוגבלת';
          isGranted = false;
          break;
        case PermissionStatus.limited:
          statusText = 'הרשאה מוגבלת';
          isGranted = true;
          break;
        case PermissionStatus.permanentlyDenied:
          statusText = 'הרשאה נדחתה לצמיתות';
          isGranted = false;
          break;
        default:
          statusText = 'לא נבדק';
          isGranted = false;
      }
      
      return {
        'success': isGranted,
        'status': statusText,
        'isGranted': isGranted,
        'message': isGranted ? 'הרשאות התראות אושרו' : 'הרשאות התראות נדחו',
        'permission': status.toString(),
      };
    } catch (e) {
      debugPrint('Notification permission request error: $e');
      return {
        'success': false,
        'status': 'שגיאה',
        'isGranted': false,
        'message': 'התראות לא נתמכות כרגע (flutter_local_notifications הוסר בגלל בעיות build ב-Windows)',
      };
    }
  }

  /// Request notification permission and send notification
  Future<Map<String, dynamic>?> sendNotification(String title, String body) async {
    // Notifications not supported - flutter_local_notifications removed due to Windows build issues
    return {
      'success': false,
      'message': 'התראות לא נתמכות כרגע (flutter_local_notifications הוסר בגלל בעיות build ב-Windows)'
    };
  }

  /// Get storage information
  Future<Map<String, dynamic>?> getStorageInfo() async {
    try {
      if (kIsWeb) {
        return {
          'success': false,
          'message': 'לא נתמך בדפדפן'
        };
      }
      
      // This is a simplified version - full implementation would use path_provider
      return {
        'success': true,
        'message': 'מידע אחסון זמין',
        'available': 'N/A',
        'total': 'N/A',
      };
    } catch (e) {
      debugPrint('Storage error: $e');
      return {
        'success': false,
        'message': 'שגיאה בקבלת מידע אחסון: $e'
      };
    }
  }

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  
  final Map<String, dynamic> _lastSensorData = {
    'accelerometer': {'x': 0.0, 'y': 0.0, 'z': 0.0},
    'gyroscope': {'x': 0.0, 'y': 0.0, 'z': 0.0},
    'magnetometer': {'x': 0.0, 'y': 0.0, 'z': 0.0},
  };

  /// Start sensor data collection
  Future<Map<String, dynamic>?> startSensors() async {
    try {
      // Start accelerometer
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        _lastSensorData['accelerometer'] = {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        };
      });

      // Start gyroscope
      _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
        _lastSensorData['gyroscope'] = {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        };
      });

      // Start magnetometer
      _magnetometerSubscription = magnetometerEventStream().listen((event) {
        _lastSensorData['magnetometer'] = {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        };
      });

      return {
        'success': true,
        'message': 'חיישנים הופעלו',
      };
    } catch (e) {
      debugPrint('Sensor start error: $e');
      return {
        'success': false,
        'message': 'שגיאה בהפעלת חיישנים: $e',
      };
    }
  }

  /// Stop sensor data collection
  Future<Map<String, dynamic>?> stopSensors() async {
    try {
      await _accelerometerSubscription?.cancel();
      await _gyroscopeSubscription?.cancel();
      await _magnetometerSubscription?.cancel();
      
      _accelerometerSubscription = null;
      _gyroscopeSubscription = null;
      _magnetometerSubscription = null;

      return {
        'success': true,
        'message': 'חיישנים הופסקו',
      };
    } catch (e) {
      debugPrint('Sensor stop error: $e');
      return {
        'success': false,
        'message': 'שגיאה בעצירת חיישנים: $e',
      };
    }
  }

  /// Get current sensor data
  Future<Map<String, dynamic>?> getSensorData() async {
    try {
      return {
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accelerometer': _lastSensorData['accelerometer'],
        'gyroscope': _lastSensorData['gyroscope'],
        'magnetometer': _lastSensorData['magnetometer'],
      };
    } catch (e) {
      debugPrint('Get sensor data error: $e');
      return {
        'success': false,
        'message': 'שגיאה בקבלת נתוני חיישנים: $e',
      };
    }
  }

  /// Get network status
  Future<Map<String, dynamic>?> getNetworkStatus() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      
      String connectionType = 'לא מחובר';
      bool isConnected = false;
      
      // connectivity_plus returns List<ConnectivityResult>
      if (connectivityResults.contains(ConnectivityResult.mobile)) {
        connectionType = 'נייד';
        isConnected = true;
      } else if (connectivityResults.contains(ConnectivityResult.wifi)) {
        connectionType = 'WiFi';
        isConnected = true;
      } else if (connectivityResults.contains(ConnectivityResult.ethernet)) {
        connectionType = 'Ethernet';
        isConnected = true;
      } else if (connectivityResults.contains(ConnectivityResult.none) || connectivityResults.isEmpty) {
        connectionType = 'לא מחובר';
        isConnected = false;
      }
      
      return {
        'success': true,
        'connected': isConnected,
        'type': connectionType,
        'status': connectivityResults.toString(),
      };
    } catch (e) {
      debugPrint('Network error: $e');
      return {
        'success': false,
        'message': 'שגיאה בבדיקת רשת: $e'
      };
    }
  }
}

