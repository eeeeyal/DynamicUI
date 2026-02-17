# iOS Setup Instructions

## דרישות מקדימות

1. **Mac עם macOS** - בניית iOS דורשת Mac
2. **Xcode** - הורד מ-App Store (גרסה 14.0 ומעלה)
3. **CocoaPods** - התקן עם:
   ```bash
   sudo gem install cocoapods
   ```

## שלבי התקנה

### 1. התקן את התלויות:
```bash
cd ios
pod install
cd ..
```

### 2. פתח את הפרויקט ב-Xcode:
```bash
open ios/Runner.xcworkspace
```

### 3. הגדר את ה-Bundle Identifier:
- פתח את `Runner.xcodeproj` ב-Xcode
- בחר את ה-target `Runner`
- בחר את ה-Tab `Signing & Capabilities`
- שנה את ה-Bundle Identifier למשהו ייחודי (למשל: `com.yourcompany.dynamicUIApp`)

### 4. בחר מכשיר או סימולטור:
- בחר מכשיר iOS מחובר או סימולטור מהתפריט למעלה

### 5. הרץ את האפליקציה:
```bash
flutter run -d ios
```

או לחץ על כפתור ה-Play ב-Xcode

## הרשאות

כל ההרשאות הנדרשות כבר מוגדרות ב-`Info.plist`:
- ✅ מיקום (`NSLocationWhenInUseUsageDescription`)
- ✅ מצלמה (`NSCameraUsageDescription`)
- ✅ גלריית תמונות (`NSPhotoLibraryUsageDescription`)
- ✅ אנשי קשר (`NSContactsUsageDescription`)
- ✅ התראות (`NSUserNotificationsUsageDescription`)

## פתרון בעיות

### אם יש שגיאת Pods:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### אם יש שגיאת signing:
- ודא שיש לך Apple Developer Account
- או בחר "Automatically manage signing" ב-Xcode

### אם יש שגיאת build:
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```




