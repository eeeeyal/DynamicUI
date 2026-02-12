# 🍎 מדריך בנייה ל-iOS - שלב אחר שלב

מדריך מפורט לבניית האפליקציה לאייפון.

## ⚠️ דרישות מקדימות (חובה!)

### 1. Mac עם macOS
- **אי אפשר לבנות ל-iOS מ-Windows/Linux**
- צריך Mac פיזי או Mac בשרת CI/CD

### 2. Xcode
- הורד מ-App Store (חינמי)
- גרסה 14.0 ומעלה מומלצת
- פתח Xcode פעם אחת כדי להתקין components נוספים

### 3. CocoaPods
```bash
sudo gem install cocoapods
```

אם יש שגיאה:
```bash
sudo gem install cocoapods --user-install
```

### 4. Apple Developer Account
- **Apple ID חינמי** - מספיק לבדיקות על סימולטור/מכשיר שלך
- **Apple Developer Program** ($99/שנה) - חובה ל-App Store

## 🚀 שלב 1: התקנת תלויות

```bash
cd flutter_app/ios
pod install
cd ../..
```

אם יש שגיאה:
```bash
cd flutter_app/ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ../..
```

## 🔧 שלב 2: הגדרת Signing

### דרך Xcode (מומלץ):

1. **פתח את הפרויקט:**
```bash
cd flutter_app/ios
open Runner.xcworkspace
```

2. **בחר את ה-target `Runner`** (בסרגל השמאלי)

3. **בחר את ה-Tab `Signing & Capabilities`**

4. **הגדר:**
   - **Bundle Identifier:** שנה למשהו ייחודי (למשל: `com.yourname.dynamicUIApp`)
   - **Team:** בחר את ה-Team שלך (או הוסף Apple ID)
   - **Automatically manage signing:** ✅ סמן

5. **שמור** (Cmd+S)

### דרך Flutter (אלטרנטיבה):

```bash
cd flutter_app
flutter build ios --release --no-codesign
```

אז פתח ב-Xcode והגדר signing ידנית.

## 📱 שלב 3: בחירת מכשיר

### אפשרות א': סימולטור (קל יותר)

1. ב-Xcode: **Product → Destination → iPhone Simulator**
2. בחר iPhone (למשל: iPhone 15 Pro)

### אפשרות ב': מכשיר פיזי

1. חבר את האייפון ל-Mac
2. **אמון במחשב** על האייפון
3. ב-Xcode: **Product → Destination → [המכשיר שלך]**

## 🏗️ שלב 4: בנייה והרצה

### דרך Flutter (מומלץ):

```bash
cd flutter_app

# בדוק מכשירים זמינים
flutter devices

# הרץ על סימולטור
flutter run -d ios

# או הרץ על מכשיר ספציפי
flutter run -d <device-id>
```

### דרך Xcode:

1. פתח `ios/Runner.xcworkspace`
2. בחר מכשיר/סימולטור מהתפריט למעלה
3. לחץ על **▶️ Play** או לחץ `Cmd+R`

## 📦 שלב 5: בניית Release

### לבדיקות (Ad Hoc):

```bash
cd flutter_app
flutter build ios --release
```

אז ב-Xcode:
1. **Product → Archive**
2. **Distribute App**
3. **Ad Hoc** (לבדיקות)
4. בחר את המכשירים
5. **Export**

### ל-App Store:

```bash
cd flutter_app
flutter build ios --release
```

אז ב-Xcode:
1. **Product → Archive**
2. **Distribute App**
3. **App Store Connect**
4. **Upload**

## 🔍 פתרון בעיות נפוצות

### שגיאת Pods:

```bash
cd flutter_app/ios
rm -rf Pods Podfile.lock .symlinks
pod cache clean --all
pod install
```

### שגיאת Signing:

1. ודא שיש לך Apple ID ב-Xcode
2. ודא שה-Bundle Identifier ייחודי
3. ודא ש-"Automatically manage signing" מסומן

### שגיאת Xcode:

```bash
# בדוק את הגרסה
xcodebuild -version

# קבל רישיון
sudo xcodebuild -license accept

# הגדר את ה-path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### שגיאת Flutter:

```bash
flutter doctor
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```

## 📊 הגדלים הצפויים:

| סוג בנייה | גודל משוער |
|-----------|------------|
| Debug | 50-80MB |
| Release (IPA) | 30-50MB |
| App Store (compressed) | 20-40MB |

## ✅ מה כבר מוכן:

- ✅ `Info.plist` עם כל ההרשאות
- ✅ `Podfile` מוגדר
- ✅ `AppDelegate.swift` מוכן
- ✅ כל הקבצים הנדרשים

## 🎯 סיכום מהיר:

```bash
# 1. התקן CocoaPods
sudo gem install cocoapods

# 2. התקן תלויות
cd flutter_app/ios
pod install
cd ../..

# 3. פתח ב-Xcode והגדר signing
open flutter_app/ios/Runner.xcworkspace

# 4. הרץ
cd flutter_app
flutter run -d ios
```

## 📚 תיעוד נוסף:

- [SETUP_MAC.md](ios/SETUP_MAC.md) - הוראות מפורטות ל-Mac
- [BUILD_RELEASE.md](BUILD_RELEASE.md) - הוראות בניית release

---

**זכור:** בניית iOS דורשת Mac! אם אין לך Mac, השתמש ב-CI/CD (GitHub Actions, Codemagic, וכו').

