# הוראות התקנת Flutter

## התקנת Flutter ב-Windows

### שלב 1: הורדת Flutter

1. הורד את Flutter מ: https://docs.flutter.dev/get-started/install/windows
2. או ישירות: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.x.x-stable.zip

### שלב 2: חילוץ והתקנה

1. חלץ את ה-ZIP לתיקייה (למשל: `C:\src\flutter`)
2. **אל תמקם** את Flutter בתיקיות שדורשות הרשאות מיוחדות כמו:
   - `C:\Program Files\`
   - `C:\Users\<username>\AppData\Local\`

### שלב 3: הוספה ל-PATH

1. פתח **System Properties** → **Environment Variables**
2. בחר ב-**Path** תחת **User variables**
3. לחץ **Edit** → **New**
4. הוסף את הנתיב: `C:\src\flutter\bin` (או הנתיב שלך)
5. לחץ **OK** בכל החלונות

### שלב 4: בדיקה

פתח PowerShell חדש והרץ:

```powershell
flutter doctor
```

זה יבדוק אם הכל מותקן נכון.

### שלב 5: התקנת תלויות

```powershell
flutter doctor --android-licenses
```

אם יש בעיות, ראה: https://docs.flutter.dev/get-started/install/windows

---

## התקנה מהירה (אם יש Chocolatey)

```powershell
choco install flutter
```

---

## אחרי ההתקנה

```powershell
cd flutter_app
flutter pub get
flutter doctor
flutter run
```

---

## פתרון בעיות

### Flutter לא מזוהה ב-PowerShell

1. סגור את כל חלונות ה-PowerShell
2. פתח PowerShell חדש
3. נסה שוב: `flutter --version`

### בעיות עם Android Studio

- התקן Android Studio מ: https://developer.android.com/studio
- פתח Android Studio → **More Actions** → **SDK Manager**
- התקן **Android SDK**, **Android SDK Platform**, ו-**Android Virtual Device**

### בעיות עם Xcode (רק ל-iOS, macOS בלבד)

- התקן Xcode מ-App Store
- הרץ: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

---

## בדיקה מהירה

```powershell
flutter --version
flutter doctor
```

אם הכל תקין, תראה:

```
Flutter 3.x.x • channel stable • ...
```

---

## קישורים שימושיים

- תיעוד Flutter: https://docs.flutter.dev
- מדריך התקנה מלא: https://docs.flutter.dev/get-started/install/windows
- פתרון בעיות: https://docs.flutter.dev/get-started/install/windows#android-setup

