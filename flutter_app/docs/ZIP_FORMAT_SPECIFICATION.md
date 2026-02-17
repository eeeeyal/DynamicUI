# פורמט ZIP - מפרט מלא

## סקירה כללית

האפליקציה מקבלת קובץ ZIP מהשרת שמכיל את כל המידע הדרוש לבניית ה-UI. הפורמט פשוט, סטנדרטי, ונוח לשימוש.

## מבנה ה-ZIP

```
app-config.zip
├── config.json          # קובץ הקונפיגורציה הראשי (חובה)
└── images/              # תיקיית תמונות (אופציונלי)
    ├── photo.png
    ├── settings.png
    └── ...
```

## קובץ config.json

### מבנה בסיסי

```json
{
  "version": "1.0.0",
  "screens": [
    {
      "id": "home",
      "type": "list",
      "title": "בית",
      "items": [
        {
          "id": "item1",
          "title": "תמונות",
          "subtitle": "צפה בתמונות מהזיכרון",
          "icon": "images/photo.png",
          "route": "/photos"
        }
      ]
    }
  ],
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF"
  }
}
```

### שדות חובה

- **version** (string): גרסת הקונפיגורציה
- **screens** (array): רשימת מסכים
- **theme** (object): הגדרות עיצוב

### Screen Object

```json
{
  "id": "unique_screen_id",
  "type": "list",
  "title": "כותרת המסך",
  "items": []
}
```

**סוגי מסכים נתמכים:**
- `list` - רשימת פריטים
- `html` - תוכן HTML (דורש `htmlPath`)

### Screen Item Object

```json
{
  "id": "unique_item_id",
  "title": "כותרת הפריט",
  "subtitle": "תת-כותרת (אופציונלי)",
  "icon": "images/icon.png",
  "route": "/path"
}
```

### Theme Object

```json
{
  "primaryColor": "#1976D2",
  "secondaryColor": "#424242",
  "backgroundColor": "#FFFFFF"
}
```

**פורמט צבעים:** Hex (#RRGGBB)

## דוגמה מלאה

ראה את הקובץ `example_app_config.zip` שנוצר על ידי הסקריפט `create_example_zip.ps1`.

## טעינת תמונות מהזיכרון

האפליקציה טוענת תמונות מהזיכרון המקומי (מחולץ מה-ZIP) באופן הבא:

1. ה-ZIP מחולץ לתיקייה מקומית
2. התמונות נשמרות בתיקיית `images/`
3. האפליקציה טוענת תמונות דרך הנתיב: `{assetsPath}/images/{filename}`

**דוגמה:**
```json
{
  "icon": "images/photo.png"
}
```

האפליקציה תחפש את הקובץ ב: `{extracted_path}/images/photo.png`

## כללים חשובים

1. **קובץ config.json חייב להיות בשורש ה-ZIP**
2. **נתיבי תמונות יחסיים לשורש ה-ZIP**
3. **תמונות חייבות להיות בפורמט PNG, JPG, או JPEG**
4. **גודל מקסימלי מומלץ: 10MB ל-ZIP כולו**
5. **קידוד: UTF-8 עבור config.json**

## דוגמת שרת (Laravel)

```php
public function getAppConfig()
{
    $zipPath = storage_path('app/app-config.zip');
    
    return response()->download($zipPath, 'app-config.zip', [
        'Content-Type' => 'application/zip',
    ]);
}
```

## בדיקת תקינות

לפני שליחה, ודא:
- ✅ ה-ZIP נפתח ללא שגיאות
- ✅ קובץ `config.json` קיים בשורש
- ✅ כל התמונות קיימות בנתיבים המצוינים
- ✅ ה-JSON תקין (ניתן לבדוק ב-jsonlint.com)
- ✅ כל השדות החובה קיימים

