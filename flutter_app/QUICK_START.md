# Quick Start - התחלה מהירה

## לפני שמתחילים

**חובה:** התקן Flutter לפני שממשיכים. ראה `INSTALL.md` להוראות.

---

## שלבים מהירים

### 1. בדוק שהכל עובד

```powershell
flutter --version
flutter doctor
```

### 2. התקן את התלויות

```powershell
cd flutter_app
flutter pub get
```

### 3. הפעל את האפליקציה

**על Android Emulator:**
```powershell
flutter run
```

**על מכשיר פיזי:**
- הפעל **USB Debugging** במכשיר
- חבר את המכשיר למחשב
- הרץ: `flutter devices` כדי לראות את המכשיר
- הרץ: `flutter run`

**על iOS Simulator (רק ב-macOS):**
```powershell
flutter run
```

---

## הגדרת כתובת ה-ZIP

בפעם הראשונה שהאפליקציה נפתחת:

1. הזן את כתובת ה-ZIP מהשרת Laravel
2. לדוגמה: `https://your-server.com/api/app/config.zip`
3. לחץ **Load Config**

האפליקציה תוריד את ה-ZIP, תפרסר אותו, ותציג את המסכים.

---

## מבנה ה-ZIP מהשרת

ה-ZIP צריך להכיל:

```
app-config.zip
├── config.json          # קונפיגורציית המסכים (חובה!)
└── assets/              # תמונות ואייקונים (אופציונלי)
    └── icons/
        └── ...
```

ראה `example_config.json` לדוגמה של מבנה ה-config.

---

## בדיקת Offline Mode

1. הפעל את האפליקציה עם חיבור לאינטרנט
2. טען את הקונפיגורציה
3. כבה את ה-WiFi/Data
4. סגור את האפליקציה ופתח שוב
5. האפליקציה אמורה לעבוד עם הקונפיגורציה השמורה

---

## פתרון בעיות

### שגיאת "No devices found"

**Android:**
- ודא ש-USB Debugging מופעל
- הרץ: `adb devices` כדי לבדוק חיבור

**iOS:**
- פתח Xcode → Window → Devices and Simulators
- ודא שיש Simulator זמין

### שגיאת "pub get failed"

```powershell
flutter clean
flutter pub get
```

### האפליקציה לא מורידה את ה-ZIP

- ודא שיש חיבור לאינטרנט
- בדוק שהכתובת נכונה
- בדוק שה-ZIP נגיש (נסה לפתוח בדפדפן)

---

## מה הלאה?

- ראה `README.md` למידע נוסף
- ראה `USAGE.md` להסבר מפורט על השימוש
- ראה `example_config.json` לדוגמה של קונפיגורציה

