# הוראות התקנת Flutter - שלב אחר שלב

## מה יש לך?
קובץ: `flutter_windows_3.38.9-stable.zip`

## מה לעשות עכשיו?

### אופציה 1: שימוש בסקריפט (מומלץ)

1. **הרץ את הסקריפט:**
   ```powershell
   .\install_flutter.ps1
   ```

2. **הסקריפט יבקש:**
   - איפה נמצא ה-ZIP (אם לא נמצא אוטומטית)
   - לאן לחלץ (ברירת מחדל: `C:\src\flutter`)

3. **אחרי ההתקנה:**
   - סגור את PowerShell
   - פתח PowerShell חדש
   - הרץ: `flutter doctor`

### אופציה 2: התקנה ידנית

#### שלב 1: חילוץ ה-ZIP

1. **מצא את הקובץ** `flutter_windows_3.38.9-stable.zip`
   - בדרך כלל ב-`Downloads` או `Desktop`

2. **חלץ את ה-ZIP:**
   - לחץ ימני על הקובץ → **Extract All...**
   - בחר מיקום (מומלץ: `C:\src\flutter`)
   - לחץ **Extract**

   **או דרך PowerShell:**
   ```powershell
   Expand-Archive -Path "C:\Users\eyal\Downloads\flutter_windows_3.38.9-stable.zip" -DestinationPath "C:\src"
   ```

#### שלב 2: הוספה ל-PATH

1. **פתח System Properties:**
   - לחץ `Win + R`
   - הקלד: `sysdm.cpl`
   - לחץ Enter

2. **הוסף ל-PATH:**
   - לחץ על **Environment Variables**
   - תחת **User variables**, בחר **Path**
   - לחץ **Edit**
   - לחץ **New**
   - הוסף: `C:\src\flutter\bin`
   - לחץ **OK** בכל החלונות

#### שלב 3: בדיקה

1. **סגור את כל חלונות PowerShell/CMD**

2. **פתח PowerShell חדש**

3. **בדוק שהכל עובד:**
   ```powershell
   flutter --version
   flutter doctor
   ```

## אחרי ההתקנה

### התקן את התלויות של הפרויקט:

```powershell
cd flutter_app
flutter pub get
```

### הפעל את האפליקציה:

```powershell
flutter run
```

## פתרון בעיות

### "flutter is not recognized"

- ודא שהוספת ל-PATH
- **סגור ופתח PowerShell מחדש**
- נסה: `refreshenv` (אם יש Chocolatey)

### שגיאת הרשאות

- הרץ PowerShell כ-**Administrator**
- או בחר מיקום אחר (לא `C:\Program Files`)

### flutter doctor מראה בעיות

- התקן **Android Studio** (ל-Android)
- התקן **Git for Windows**
- ראה: https://docs.flutter.dev/get-started/install/windows

## קישורים שימושיים

- תיעוד Flutter: https://docs.flutter.dev
- פתרון בעיות: https://docs.flutter.dev/get-started/install/windows#android-setup


