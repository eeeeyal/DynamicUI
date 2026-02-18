# Dynamic UI - Server-Driven UI Engine

אפליקציית Flutter דינמית שמקבלת קונפיגורציה מ-ZIP ובונה UI native לפי הקונפיגורציה.

## 📁 מבנה הפרויקט:

```
DynamicUI/
├── docs/              # 📚 כל התיעוד (.md)
├── scripts/           # 🔧 כל ה-Scripts (.ps1)
├── flutter_app/       # 📱 אפליקציית Flutter
├── html_screens/      # 🌐 קבצי HTML לדוגמה
├── demo_app_v1/       # 📦 דוגמת קונפיגורציה
└── output/            # 📤 קבצי פלט
```

## 🚀 התחלה מהירה:

1. **קרא את התיעוד:**
   - [תיעוד ראשי](docs/README.md)
   - [הרצה מהירה](docs/QUICK_RUN.md)
   - [הוראות שימוש](docs/USAGE.md)

2. **התקן Flutter:**
   - [הוראות התקנה](docs/FLUTTER_INSTALL_STEPS.md)
   - או הרץ: `.\scripts\install_flutter.ps1`

3. **הרץ את האפליקציה:**
   ```bash
   cd flutter_app
   flutter run
   ```

## 📚 תיעוד:

כל התיעוד נמצא ב-[`docs/`](docs/):
- תיעוד כללי
- פורמטים ומפרטים
- הוראות התקנה

תיעוד Flutter נמצא ב-[`flutter_app/`](flutter_app/):
- ארכיטקטורה
- מדריך למפתחים
- הוראות בנייה

## 🔧 Scripts:

כל ה-Scripts נמצאים ב-[`scripts/`](scripts/):
- התקנה והגדרה
- המרה ויצירת קבצים
- כלים נוספים

ראה [README של Scripts](scripts/README.md) לפרטים.

## 📦 פורמט ZIP:

האפליקציה תומכת בפורמט ZIP דינמי. ראה:
- [מדריך פורמט ZIP](docs/ZIP_FORMAT_GUIDE.md)
- [מפרט טכני](docs/ZIP_FORMAT_SPECIFICATION.md)

## 🌟 תכונות:

✅ **תמיכה מלאה ב-iOS, Android ו-Windows**  
✅ **UI Native לחלוטין** (לא WebView)  
✅ **טעינת קונפיגורציה מ-ZIP**  
✅ **תמיכה בתמונות מהזיכרון**  
✅ **עיצוב רספונסיבי אוטומטי**  
✅ **מצב Offline**  
✅ **הרשאות דינמיות** (מיקום, מצלמה, אנשי קשר, וכו')  
✅ **חיישנים ורשת**  

## 📱 פלטפורמות נתמכות:

- ✅ Android
- ✅ iOS (דורש Mac לבנייה)
- ✅ Windows
- ✅ Web

## 🔗 קישורים:

- [תיעוד מלא](docs/)
- [Scripts](scripts/)
- [Flutter App](flutter_app/)
