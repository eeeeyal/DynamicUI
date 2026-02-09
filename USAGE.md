# Dynamic UI - הוראות שימוש

## מה נבנה?

אפליקציית Flutter שמקבלת ZIP מהשרת Laravel, מפרסת אותו, ובונה UI דינמי לפי הקונפיגורציה.

## מבנה הפרויקט

```
DynamicUI/
└── flutter_app/          # אפליקציית Flutter
    ├── lib/
    │   ├── main.dart                    # נקודת כניסה
    │   ├── models/                      # מודלים (AppConfig, ScreenConfig)
    │   ├── services/                    # שירותים
    │   │   ├── zip_service.dart         # הורדה וחילוץ ZIP
    │   │   ├── config_service.dart      # ניהול קונפיגורציה
    │   │   └── storage_service.dart     # שמירה מקומית
    │   ├── screens/                     # מסכים
    │   │   ├── home_screen.dart         # מסך ראשי
    │   │   └── dynamic_list_screen.dart # מסך רשימה דינמי
    │   └── widgets/                     # ווידג'טים
    │       └── dynamic_screen_builder.dart
    └── example_config.json              # דוגמה לקונפיגורציה
```

## איך זה עובד?

1. **השרת (Laravel)** מחזיר ZIP עם:
   - `config.json` - קונפיגורציית המסכים
   - `assets/` - תמונות ואייקונים

2. **האפליקציה (Flutter)**:
   - מורידה את ה-ZIP
   - מחלצת אותו
   - מפרסת את `config.json`
   - בונה UI דינמי לפי הקונפיגורציה
   - שומרת מקומית (Offline mode)

## התקנה והרצה

```bash
cd flutter_app
flutter pub get
flutter run
```

## הגדרת כתובת ה-ZIP

בפעם הראשונה, האפליקציה תציג מסך להזנת כתובת ה-ZIP.

או תוכל להגדיר ב-`lib/config/app_config.dart`:

```dart
static const String defaultZipUrl = 'https://your-server.com/api/app/config.zip';
```

## מבנה ה-ZIP מהשרת

ה-ZIP צריך להכיל:

```
app-config.zip
├── config.json
└── assets/
    └── icons/
        ├── orders.png
        ├── reports.png
        └── ...
```

## מבנה config.json

ראה `example_config.json` לדוגמה מלאה.

המבנה הבסיסי:

```json
{
  "version": "1.0.0",
  "screens": [
    {
      "id": "home",
      "type": "list",
      "title": "Dashboard",
      "items": [...]
    }
  ],
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF"
  }
}
```

## תכונות

- ✅ **Offline Mode** - האפליקציה עובדת גם בלי אינטרנט
- ✅ **Versioning** - בודקת אוטומטית עדכונים
- ✅ **Dynamic UI** - בונה מסכים לפי הקונפיגורציה
- ✅ **Android + iOS** - קוד אחד לשתי הפלטפורמות

## סוגי מסכים נתמכים

כרגע נתמך:
- `list` - מסך רשימה עם פריטים

ניתן להוסיף:
- `form` - מסך טופס
- `detail` - מסך פרטים
- ועוד...

## הוספת סוג מסך חדש

1. הוסף case ב-`lib/widgets/dynamic_screen_builder.dart`
2. צור מסך חדש ב-`lib/screens/`
3. הוסף את הטיפוס ב-`config.json`

## שאלות?

הכל מוכן לשימוש! פשוט הפעל את האפליקציה והזן את כתובת ה-ZIP מהשרת.

