# פורמט Config - JSON + ZIP

## סקירה כללית

האפליקציה תומכת בשני פורמטים:

1. **JSON Config בתוך ZIP** - הקובץ `config.json` נמצא בתוך ה-ZIP יחד עם assets
2. **JSON Config נפרד + ZIP Assets** - JSON נפרד + ZIP עם רק assets

## פורמט 1: JSON בתוך ZIP (מומלץ)

```
app-config.zip
├── config.json          # הקובץ הראשי עם הגדרות המסכים
├── images/
│   ├── logo.png
│   └── icon.png
└── assets/
    └── fonts/
        └── custom.ttf
```

## פורמט 2: JSON נפרד + ZIP Assets

```
# שליחה נפרדת:
1. GET /api/config.json  → JSON config
2. GET /api/assets.zip   → ZIP עם רק assets
```

## מבנה config.json

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
          "type": "button",
          "title": "הגדרות",
          "icon": "images/settings.png",
          "action": {
            "type": "navigate",
            "screenId": "settings"
          }
        }
      ]
    },
    {
      "id": "html_content",
      "type": "html",
      "title": "HTML Content",
      "htmlPath": "index.html"
    }
  ],
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF"
  }
}
```

## סוגי מסכים (Screen Types)

### 1. `list` - רשימת פריטים
```json
{
  "id": "home",
  "type": "list",
  "title": "בית",
  "items": [
    {
      "id": "item1",
      "type": "button",
      "title": "פריט 1",
      "subtitle": "תיאור",
      "icon": "images/icon.png"
    }
  ]
}
```

### 2. `html` - HTML Native
```json
{
  "id": "html_content",
  "type": "html",
  "title": "HTML Content",
  "htmlPath": "index.html"
}
```

### 3. `form` - טופס (עתידי)
```json
{
  "id": "contact_form",
  "type": "form",
  "title": "צור קשר",
  "fields": [
    {
      "id": "name",
      "type": "text",
      "label": "שם",
      "required": true
    }
  ]
}
```

## סוגי פריטים (Item Types)

### `button` - כפתור
```json
{
  "id": "settings",
  "type": "button",
  "title": "הגדרות",
  "subtitle": "ניהול הגדרות",
  "icon": "images/settings.png",
  "action": {
    "type": "navigate",
    "screenId": "settings"
  }
}
```

### `card` - כרטיס
```json
{
  "id": "card1",
  "type": "card",
  "title": "כותרת",
  "subtitle": "תת כותרת",
  "image": "images/card.png",
  "content": "תוכן הכרטיס"
}
```

## Actions

### `navigate` - ניווט למסך אחר
```json
{
  "type": "navigate",
  "screenId": "settings"
}
```

### `url` - פתיחת URL
```json
{
  "type": "url",
  "url": "https://example.com"
}
```

### `action` - פעולה מותאמת אישית
```json
{
  "type": "action",
  "actionId": "custom_action",
  "params": {
    "key": "value"
  }
}
```

## Theme

```json
{
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF",
    "textColor": "#000000",
    "fontFamily": "Roboto"
  }
}
```

## דוגמה מלאה

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
          "id": "settings",
          "type": "button",
          "title": "הגדרות",
          "icon": "images/settings.png",
          "action": {
            "type": "navigate",
            "screenId": "settings"
          }
        },
        {
          "id": "about",
          "type": "button",
          "title": "אודות",
          "icon": "images/info.png",
          "action": {
            "type": "navigate",
            "screenId": "about"
          }
        }
      ]
    },
    {
      "id": "html_content",
      "type": "html",
      "title": "HTML Content",
      "htmlPath": "index.html"
    }
  ],
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF"
  }
}
```

## הערות

1. **Paths** - כל ה-paths ב-JSON הם יחסיים לתיקיית ה-extracted ZIP
2. **Images** - תמונות צריכות להיות בתוך ה-ZIP
3. **HTML** - אם יש `htmlPath`, הקובץ צריך להיות בתוך ה-ZIP
4. **Version** - כל עדכון צריך version חדש

