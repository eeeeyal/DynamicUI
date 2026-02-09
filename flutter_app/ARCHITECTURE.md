# ארכיטקטורה - Dynamic UI App

## סקירה כללית

אפליקציית Flutter שמקבלת ZIP מהשרת Laravel, מפרסת אותו, ובונה UI דינמי לפי הקונפיגורציה.

## זרימת הנתונים

```
Laravel Server
    ↓ (HTTPS)
    ZIP File (config.json + assets/)
    ↓
Flutter App
    ├─ Download ZIP
    ├─ Extract ZIP
    ├─ Parse config.json
    ├─ Cache locally (Offline)
    └─ Build Dynamic UI
```

## מבנה הקבצים

### Services (שירותים)

#### `zip_service.dart`
- **תפקיד:** הורדה וחילוץ ZIP
- **פונקציות עיקריות:**
  - `downloadZip()` - הורדת ZIP מהשרת
  - `extractAndParseConfig()` - חילוץ ZIP ופרסור config.json
  - `getExtractedAssetsPath()` - קבלת נתיב ל-assets מחולצים
  - `saveConfigUrl()` / `getConfigUrl()` - שמירת כתובת ZIP
  - `saveLastVersion()` / `getLastVersion()` - ניהול גרסאות

#### `config_service.dart`
- **תפקיד:** ניהול קונפיגורציה מרכזי
- **פונקציות עיקריות:**
  - `loadConfig()` - טעינת קונפיגורציה (online/offline)
  - `_checkForUpdates()` - בדיקת עדכונים ברקע
  - `getAssetPath()` - קבלת נתיב לתמונה/אייקון

#### `storage_service.dart`
- **תפקיד:** שמירה מקומית (Offline)
- **פונקציות עיקריות:**
  - `cacheConfig()` - שמירת קונפיגורציה
  - `getCachedConfig()` - טעינת קונפיגורציה שמורה
  - `clearCache()` - ניקוי cache

### Models (מודלים)

#### `app_config.dart`
- **AppConfig** - מודל ראשי לקונפיגורציה
  - `version` - גרסה
  - `screens` - רשימת מסכים
  - `theme` - הגדרות עיצוב

- **ScreenConfig** - מודל למסך
  - `id` - מזהה מסך
  - `type` - סוג מסך (list/form/detail)
  - `title` - כותרת
  - `items` - פריטים במסך

- **ScreenItem** - מודל לפריט במסך
  - `id` - מזהה
  - `title` - כותרת
  - `subtitle` - תת-כותרת
  - `icon` - נתיב לאייקון
  - `route` - נתיב לניווט

- **ThemeConfig** - מודל לעיצוב
  - `primaryColor` - צבע ראשי
  - `secondaryColor` - צבע משני
  - `backgroundColor` - צבע רקע

### Screens (מסכים)

#### `home_screen.dart`
- מסך ראשי שמציג את המסך הראשון מה-config
- טיפול בשגיאות וטעינה
- אפשרות להזנת כתובת ZIP

#### `dynamic_list_screen.dart`
- מסך רשימה דינמי
- מציג פריטים לפי ה-config
- תמיכה בתמונות/אייקונים
- ניווט לפי route

### Widgets (ווידג'טים)

#### `dynamic_screen_builder.dart`
- בונה מסכים לפי סוג (type)
- תומך ב: `list`, `form`, `detail`
- ניתן להרחבה לסוגי מסכים נוספים

## זרימת עבודה

### 1. אתחול האפליקציה
```
main() 
  → StorageService.init()
  → ConfigService.loadConfig()
```

### 2. טעינת קונפיגורציה
```
loadConfig()
  → בדיקת cache (אם לא forceUpdate)
  → אם יש cache: טעינה + בדיקת עדכונים ברקע
  → אם אין cache: הורדת ZIP
    → downloadZip()
    → extractAndParseConfig()
    → שמירה ב-cache
```

### 3. בניית UI
```
HomeScreen
  → מציאת מסך home (או הראשון)
  → DynamicScreenBuilder
    → לפי type: בניית מסך מתאים
      → list → DynamicListScreen
      → form → FormScreen (TODO)
      → detail → DetailScreen (TODO)
```

### 4. Offline Mode
- אם אין חיבור: טעינה מ-cache
- אם יש חיבור: בדיקת עדכונים ברקע
- אם יש עדכון: עדכון אוטומטי

## הרחבות אפשריות

### סוגי מסכים נוספים
1. הוסף case ב-`dynamic_screen_builder.dart`
2. צור מסך חדש ב-`screens/`
3. עדכן את ה-config.json

### תכונות נוספות
- **Navigation** - מערכת ניווט דינמית לפי routes
- **Forms** - מסכי טופס דינמיים
- **API Calls** - קריאות API לפי config
- **Push Notifications** - התראות לפי config
- **Theming** - ערכות נושא דינמיות

## תלויות (Dependencies)

- `dio` - HTTP client להורדת ZIP
- `archive` - חילוץ ZIP
- `path_provider` - גישה לתיקיות מערכת
- `shared_preferences` - שמירה מקומית
- `provider` - ניהול state
- `sqflite` - מסד נתונים מקומי (לשימוש עתידי)

## ביצועים

- **Cache** - שמירה מקומית למהירות
- **Background Updates** - עדכונים ברקע ללא הפרעה
- **Lazy Loading** - טעינת מסכים לפי דרישה
- **Error Handling** - טיפול בשגיאות עם fallback ל-cache

## אבטחה

- **HTTPS** - חיבור מאובטח לשרת
- **Validation** - בדיקת תקינות config.json
- **Sanitization** - ניקוי נתיבי קבצים
- **Versioning** - בדיקת גרסאות למניעת בעיות

## הערות

- הקוד מוכן לשימוש מיד אחרי התקנת Flutter
- כל השירותים מופרדים וניתנים לבדיקה בנפרד
- ניתן להרחבה בקלות לסוגי מסכים נוספים

