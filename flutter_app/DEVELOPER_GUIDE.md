# מדריך למתכנת - פורמט ZIP ו-Config

## 📦 מבנה ZIP - מה צריך להיות בתוך הקובץ

### פורמט מומלץ: JSON Config בתוך ZIP

```
app-config.zip
│
├── config.json                    # ⚠️ חובה! קובץ ה-config הראשי
│
├── index.html                     # אופציונלי - אם יש מסך HTML
│
├── images/                        # אופציונלי - תמונות
│   ├── logo.png
│   ├── icon.png
│   └── settings.png
│
├── assets/                        # אופציונלי - קבצים נוספים
│   ├── fonts/
│   │   └── custom.ttf
│   └── data/
│       └── data.json
│
└── css/                          # אופציונלי - אם יש HTML
    └── styles.css
```

## 📄 מבנה config.json - המבנה המלא

### מבנה בסיסי

```json
{
  "version": "1.0.0",
  "screens": [
    {
      "id": "home",
      "type": "list",
      "title": "בית",
      "items": []
    }
  ],
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF"
  }
}
```

### דוגמה מלאה עם כל האפשרויות

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
          "subtitle": "ניהול הגדרות האפליקציה",
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
          "subtitle": "מידע על האפליקציה",
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
    },
    {
      "id": "settings",
      "type": "list",
      "title": "הגדרות",
      "items": [
        {
          "id": "profile",
          "type": "button",
          "title": "פרופיל",
          "icon": "images/profile.png"
        }
      ]
    }
  ],
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF",
    "textColor": "#000000"
  }
}
```

## 🎯 סוגי מסכים (Screen Types)

### 1. `list` - מסך רשימה

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
      "subtitle": "תיאור הפריט",
      "icon": "images/icon1.png"
    }
  ]
}
```

**מה האפליקציה עושה:**
- מציגה רשימה של פריטים
- ב-desktop: Grid עם 3 עמודות
- ב-tablet: Grid עם 2 עמודות
- ב-mobile: List אנכי

### 2. `html` - מסך HTML Native

```json
{
  "id": "html_content",
  "type": "html",
  "title": "HTML Content",
  "htmlPath": "index.html"
}
```

**מה האפליקציה עושה:**
- מפרסת את ה-HTML ל-Native Flutter widgets
- ממירה HTML tags ל-Widgets (לא WebView!)
- תומך ב-responsive אוטומטי

**מה צריך להיות ב-ZIP:**
- `index.html` (או כל שם שמוגדר ב-`htmlPath`)

## 📋 סוגי פריטים (Item Types)

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

**שדות:**
- `id` - מזהה ייחודי (חובה)
- `type` - תמיד `"button"` (חובה)
- `title` - כותרת הכפתור (חובה)
- `subtitle` - תת-כותרת (אופציונלי)
- `icon` - נתיב לתמונה (אופציונלי, יחסי ל-root של ZIP)
- `action` - פעולה לביצוע (אופציונלי)

## 🎨 Theme - עיצוב

```json
{
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF",
    "textColor": "#000000"
  }
}
```

**צבעים:**
- פורמט: Hex color (`#RRGGBB`)
- `primaryColor` - צבע ראשי (כפתורים, AppBar)
- `secondaryColor` - צבע משני
- `backgroundColor` - רקע כללי
- `textColor` - צבע טקסט (אופציונלי)

## 🚀 Actions - פעולות

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

## 📁 Paths - נתיבים

**כל הנתיבים ב-JSON הם יחסיים ל-root של ה-ZIP:**

```json
{
  "icon": "images/settings.png"     // ✅ נכון
  "icon": "/images/settings.png"     // ❌ לא נכון (לא להתחיל ב-/)
  "icon": "assets/images/icon.png"   // ✅ נכון
}
```

**דוגמאות:**
- `images/logo.png` → `app-config.zip/images/logo.png`
- `index.html` → `app-config.zip/index.html`
- `assets/fonts/custom.ttf` → `app-config.zip/assets/fonts/custom.ttf`

## ✅ Checklist - מה לבדוק לפני שליחה

### לפני יצירת ה-ZIP:

- [ ] קובץ `config.json` קיים ב-root של ה-ZIP
- [ ] `config.json` תקין (JSON valid)
- [ ] כל ה-`id` ייחודיים
- [ ] כל ה-`screenId` ב-actions קיימים ב-`screens`
- [ ] כל הנתיבים לתמונות נכונים
- [ ] כל התמונות קיימות ב-ZIP
- [ ] אם יש `htmlPath`, הקובץ קיים ב-ZIP
- [ ] `version` מוגדר ומעודכן

### מבנה ZIP:

- [ ] `config.json` ב-root (לא בתיקייה)
- [ ] תמונות בתיקייה `images/` (או כל שם אחר)
- [ ] HTML בתיקייה root (אם יש)
- [ ] אין תיקיות ריקות מיותרות

## 📝 דוגמה מעשית - יצירת ZIP

### שלב 1: יצירת config.json

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
          "icon": "images/settings.png"
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

### שלב 2: מבנה תיקיות

```
my-app-config/
├── config.json
└── images/
    └── settings.png
```

### שלב 3: יצירת ZIP

```bash
# Windows PowerShell
Compress-Archive -Path my-app-config\* -DestinationPath app-config.zip

# Linux/Mac
zip -r app-config.zip my-app-config/
```

### שלב 4: בדיקה

פתח את ה-ZIP ובדוק:
- ✅ `config.json` קיים ב-root
- ✅ `images/settings.png` קיים
- ✅ אין תיקיות ריקות

## 🔍 איך האפליקציה מפרסת

1. **מורידה את ה-ZIP** (או משתמשת בקובץ מקומי)
2. **מחלצת את כל הקבצים** ל-`extracted/`
3. **קוראת את `config.json`** מהתיקייה המחולצת
4. **בונה את המסכים** לפי ה-config
5. **טוענת תמונות** מהנתיבים ב-config

## ⚠️ שגיאות נפוצות

### שגיאה: "config.json not found in ZIP file"

**סיבה:** `config.json` לא ב-root של ה-ZIP

**פתרון:**
```
❌ app-config.zip/configs/config.json  (לא נכון)
✅ app-config.zip/config.json          (נכון)
```

### שגיאה: "Image not found"

**סיבה:** נתיב התמונה לא נכון

**פתרון:**
```json
// ב-config.json
{
  "icon": "images/settings.png"  // ✅ נכון
}

// ב-ZIP
app-config.zip/images/settings.png  // ✅ קיים
```

### שגיאה: "Invalid JSON"

**סיבה:** JSON לא תקין

**פתרון:** בדוק ב-https://jsonlint.com/

## 📞 דוגמה מלאה - ZIP מוכן לשימוש

```
app-config.zip
│
├── config.json
│
├── index.html
│
└── images/
    ├── logo.png
    ├── settings.png
    ├── info.png
    └── profile.png
```

**config.json:**
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
          "icon": "images/settings.png"
        },
        {
          "id": "about",
          "type": "button",
          "title": "אודות",
          "icon": "images/info.png"
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

## 🎯 סיכום - מה צריך לשלוח

1. **קובץ ZIP אחד** עם:
   - `config.json` ב-root
   - תמונות בתיקייה `images/`
   - HTML (אם יש) ב-root

2. **JSON תקין** עם:
   - `version` מעודכן
   - `screens` מוגדרים
   - `theme` מוגדר

3. **נתיבים נכונים** - כל הנתיבים יחסיים ל-root של ה-ZIP

**זה הכל!** 🎉

