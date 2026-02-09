# Dynamic UI Flutter App

אפליקציית Flutter שמקבלת ZIP מהשרת, מפרסת אותו, ובונה UI דינמי לפי הקונפיגורציה.

## תכונות

- ✅ הורדת ZIP מהשרת
- ✅ חילוץ ZIP ופרסור config.json
- ✅ UI דינמי לפי הקונפיגורציה
- ✅ Offline mode - שמירה מקומית
- ✅ תמיכה ב-Android + iOS
- ✅ Versioning - בדיקת עדכונים

## מבנה ה-ZIP

ה-ZIP צריך להכיל:

```
app-config.zip
├── config.json          # קונפיגורציית המסכים
└── assets/              # תמונות ואייקונים
    └── icons/
        └── ...
```

## מבנה config.json

```json
{
  "version": "1.0.0",
  "screens": [
    {
      "id": "home",
      "type": "list",
      "title": "Dashboard",
      "items": [
        {
          "id": "orders",
          "title": "Orders",
          "subtitle": "View all orders",
          "icon": "assets/icons/orders.png",
          "route": "/orders"
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

## התקנה

```bash
cd flutter_app
flutter pub get
flutter run
```

## שימוש

1. הפעל את האפליקציה
2. הזן את כתובת ה-ZIP מהשרת
3. האפליקציה תוריד, תפרסר, ותציג את המסכים לפי הקונפיגורציה

## Offline Mode

האפליקציה שומרת את הקונפיגורציה מקומית. אם אין חיבור לאינטרנט, היא תשתמש בגרסה השמורה.

## עדכונים

האפליקציה בודקת אוטומטית אם יש עדכון חדש לפי ה-version ב-config.json.

