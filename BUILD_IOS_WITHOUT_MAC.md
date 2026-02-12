# 🍎 בניית iOS ללא Mac - מדריך CI/CD

אם אין לך Mac, יש כמה דרכים לבנות אפליקציה לאייפון:

## 🎯 אפשרות 1: GitHub Actions (מומלץ - חינמי!)

GitHub Actions מספק Mac runners חינם לפרויקטים ציבוריים.

### שלב 1: צור קובץ `.github/workflows/ios-build.yml`

```yaml
name: Build iOS

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:  # מאפשר הרצה ידנית

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: |
        cd flutter_app
        flutter pub get
    
    - name: Install CocoaPods
      run: |
        cd flutter_app/ios
        pod install
    
    - name: Build iOS
      run: |
        cd flutter_app
        flutter build ios --release --no-codesign
    
    - name: Archive IPA
      run: |
        cd flutter_app/ios
        xcodebuild -workspace Runner.xcworkspace \
          -scheme Runner \
          -configuration Release \
          -archivePath build/Runner.xcarchive \
          archive
    
    - name: Export IPA
      run: |
        cd flutter_app/ios
        xcodebuild -exportArchive \
          -archivePath build/Runner.xcarchive \
          -exportPath build/ipa \
          -exportOptionsPlist ExportOptions.plist
    
    - name: Upload IPA
      uses: actions/upload-artifact@v3
      with:
        name: ios-app
        path: flutter_app/ios/build/ipa/*.ipa
```

### שלב 2: צור `flutter_app/ios/ExportOptions.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

### שלב 3: Push ל-GitHub

```bash
git add .github/workflows/ios-build.yml
git commit -m "Add iOS build workflow"
git push
```

**תוצאה:** GitHub יבנה את האפליקציה אוטומטית!

## 🎯 אפשרות 2: Codemagic (חינמי עד 500 דקות/חודש)

### שלב 1: הירשם ל-Codemagic
- לך ל-https://codemagic.io
- היכנס עם GitHub/GitLab/Bitbucket

### שלב 2: הוסף את הפרויקט
- בחר את ה-repository שלך
- Codemagic יזהה אוטומטית שזה Flutter

### שלב 3: הגדר build
Codemagic יוצר קובץ `codemagic.yaml` אוטומטית, או תוכל להשתמש ב-UI.

**דוגמת `codemagic.yaml`:**
```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Get dependencies
        script: |
          flutter pub get
      - name: Install CocoaPods dependencies
        script: |
          cd ios && pod install
      - name: Build iOS
        script: |
          flutter build ios --release --no-codesign
    artifacts:
      - build/ios/ipa/*.ipa
```

## 🎯 אפשרות 3: Bitrise (חינמי עד 200 דקות/חודש)

### שלב 1: הירשם ל-Bitrise
- לך ל-https://bitrise.io
- היכנס עם GitHub

### שלב 2: הוסף App
- בחר את ה-repository
- Bitrise יזהה Flutter אוטומטית

### שלב 3: הרץ Build
- בחר workflow: `primary`
- לחץ "Start Build"

## 🎯 אפשרות 4: Mac בשרת מרוחק

אם יש לך גישה ל-Mac בשרת:

```bash
# התחבר ל-Mac דרך SSH
ssh user@mac-server-ip

# Clone את הפרויקט
git clone <your-repo-url>
cd DynamicUI/flutter_app

# התקן תלויות
cd ios
pod install
cd ..

# בנה
flutter build ios --release
```

## 🎯 אפשרות 5: MacinCloud / MacStadium (שירותי Mac בענן)

שירותים מסחריים שמספקים Mac VMs:

- **MacinCloud** - החל מ-$20/חודש
- **MacStadium** - החל מ-$99/חודש
- **AWS EC2 Mac** - תשלום לפי שימוש

## 📋 השוואה:

| שירות | מחיר | קלות שימוש | מומלץ |
|-------|------|------------|--------|
| GitHub Actions | חינמי (public) | ⭐⭐⭐⭐⭐ | ✅ הכי טוב |
| Codemagic | חינמי (500 דקות) | ⭐⭐⭐⭐ | ✅ טוב מאוד |
| Bitrise | חינמי (200 דקות) | ⭐⭐⭐ | ✅ טוב |
| MacinCloud | $20+/חודש | ⭐⭐ | ⚠️ יקר |
| Mac מרוחק | תלוי | ⭐⭐ | ⚠️ דורש גישה |

## 🚀 המלצה: GitHub Actions

**יתרונות:**
- ✅ חינמי לפרויקטים ציבוריים
- ✅ אינטגרציה מלאה עם GitHub
- ✅ Mac runners מהירים
- ✅ קל להגדרה

**חסרונות:**
- ⚠️ דורש repository ציבורי (או GitHub Pro)
- ⚠️ צריך להגדיר signing

## 📝 הגדרת Signing ב-GitHub Actions

### שלב 1: צור Certificates ו-Provisioning Profile

צריך:
1. **Distribution Certificate** (מ-Apple Developer)
2. **Provisioning Profile** (מ-Apple Developer)

### שלב 2: הוסף Secrets ל-GitHub

ב-GitHub Repository → Settings → Secrets → Actions:

- `APPLE_CERTIFICATE` - Base64 של ה-certificate
- `APPLE_CERTIFICATE_PASSWORD` - סיסמה של ה-certificate
- `APPLE_PROVISIONING_PROFILE` - Base64 של ה-provisioning profile
- `APPLE_TEAM_ID` - Team ID שלך

### שלב 3: עדכן את ה-workflow

```yaml
- name: Setup certificates
  env:
    APPLE_CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}
    APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
    APPLE_PROVISIONING_PROFILE: ${{ secrets.APPLE_PROVISIONING_PROFILE }}
  run: |
    # Decode certificates
    echo "$APPLE_CERTIFICATE" | base64 --decode > certificate.p12
    echo "$APPLE_PROVISIONING_PROFILE" | base64 --decode > profile.mobileprovision
    
    # Install certificate
    security create-keychain -p "" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "" build.keychain
    security import certificate.p12 -k build.keychain -P "$APPLE_CERTIFICATE_PASSWORD" -T /usr/bin/codesign
    
    # Install provisioning profile
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
```

## 🔗 קישורים שימושיים:

- [GitHub Actions](https://github.com/features/actions)
- [Codemagic](https://codemagic.io)
- [Bitrise](https://bitrise.io)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)

---

**לסיכום:** השתמש ב-GitHub Actions אם יש לך repository ציבורי, או ב-Codemagic אם אתה צריך פרטי!

