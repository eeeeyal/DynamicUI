# דוגמה מעשית - מבנה ZIP

## 📦 מבנה ZIP מומלץ

```
app-config.zip
│
├── config.json                    # ⚠️ חובה - קובץ ה-config
│
├── index.html                     # אופציונלי - אם יש מסך HTML
│
├── images/                        # תמונות
│   ├── logo.png
│   ├── settings.png
│   ├── info.png
│   └── profile.png
│
└── assets/                        # קבצים נוספים (אופציונלי)
    └── data.json
```

## 📄 תוכן config.json

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
    "backgroundColor": "#FFFFFF"
  }
}
```

## ✅ Checklist לפני שליחה

- [ ] `config.json` קיים ב-root של ה-ZIP
- [ ] JSON תקין (בדוק ב-jsonlint.com)
- [ ] כל ה-`id` ייחודיים
- [ ] כל ה-`screenId` ב-actions קיימים
- [ ] כל הנתיבים לתמונות נכונים
- [ ] כל התמונות קיימות ב-ZIP
- [ ] אם יש `htmlPath`, הקובץ קיים
- [ ] `version` מוגדר

## 🚀 איך ליצור את ה-ZIP

### Windows PowerShell:
```powershell
# צור תיקייה
New-Item -ItemType Directory -Path my-app-config
New-Item -ItemType Directory -Path my-app-config\images

# העתק קבצים
Copy-Item config.json my-app-config\
Copy-Item *.png my-app-config\images\

# צור ZIP
Compress-Archive -Path my-app-config\* -DestinationPath app-config.zip
```

### Linux/Mac:
```bash
# צור תיקייה
mkdir -p my-app-config/images

# העתק קבצים
cp config.json my-app-config/
cp *.png my-app-config/images/

# צור ZIP
zip -r app-config.zip my-app-config/
```

## 📝 הערות חשובות

1. **config.json חובה** - חייב להיות ב-root של ה-ZIP
2. **נתיבים יחסיים** - כל הנתיבים יחסיים ל-root של ה-ZIP
3. **תמונות** - מומלץ בתיקייה `images/`
4. **HTML** - אם יש, ב-root או בתיקייה נפרדת

