# 🔄 HTML to ZIP Converter

סקריפט Python שממיר קבצי HTML לקובצי ZIP בפורמט Dynamic UI Runtime Engine.

## 📋 דרישות

```bash
pip install beautifulsoup4
```

## 🚀 שימוש

### המרת תיקייה שלמה (מומלץ)

```bash
python html_to_zip_converter.py ./html_files
```

**מה קורה:**
1. הסקריפט ימצא את כל קבצי ה-HTML בתיקייה (`*.html`, `*.htm`)
2. יציג רשימה של הקבצים שנמצאו
3. **ישאל אותך איפה ליצור את התיקייה החדשה** עם כל ה-JSONs
4. ייצור תיקייה חדשה עם כל הקבצים המרובים
5. ייצור קובץ ZIP לכל קובץ HTML בתיקיית הפלט

**דוגמה לאינטראקציה:**
```
📁 נמצאו 3 קבצי HTML:
  1. index.html
  2. settings.html
  3. dashboard.html

============================================================
📁 בחירת תיקיית פלט
============================================================

תיקייה ברירת מחדל: C:\Users\eyal\project\DynamicUI\converted_apps
הזן נתיב לתיקיית פלט (Enter לברירת מחדל): ./my_apps

✅ תיקיית פלט: C:\Users\eyal\project\DynamicUI\my_apps
🔄 מתחיל המרה של 3 קבצים...
```

### המרת תיקייה עם תיקיית פלט מוגדרת

```bash
python html_to_zip_converter.py ./html_files -o ./output
```

במקרה זה הסקריפט **לא ישאל** איפה ליצור את התיקייה - הוא ישתמש ב-`./output`.

### המרת קובץ יחיד

```bash
python html_to_zip_converter.py index.html -o ./output
```

## 📁 מבנה הפלט

לכל קובץ HTML נוצרת תיקייה עם המבנה הבא:

```
output_dir/
├── index/                    # תיקייה עם כל ה-JSONs
│   ├── app.json
│   ├── routes.json
│   ├── styles.json
│   ├── actions.json
│   ├── screens/
│   │   ├── home.json
│   │   ├── settings.json
│   │   └── ...
│   └── assets/
│       └── ...
├── index.zip                 # קובץ ZIP שנוצר מהתיקייה
├── settings/
│   ├── app.json
│   ├── routes.json
│   └── ...
└── settings.zip
```

## ✨ תכונות

- ✅ **המרה אוטומטית של טאבים למסכים נפרדים** - כל טאב הופך למסך נפרד
- ✅ **שמירה על פריסה מדויקת** - column, row, grid נשמרים
- ✅ **חילוץ צבעים מ-Tailwind CSS** - צבעים נחלצים אוטומטית
- ✅ **המרת כפתורים לפעולות ניווט** - כפתורים עם @click הופכים לפעולות
- ✅ **תמיכה ב-RTL** - זיהוי אוטומטי של RTL
- ✅ **העתקת תמונות ל-assets** - תמונות מקומיות מועתקות אוטומטית
- ✅ **עבודה על תיקייה שלמה** - המרה של כל קבצי ה-HTML בבת אחת

## 📝 הערות חשובות

- **פעולות מורכבות**: פעולות Vue.js/JavaScript יהפכו לפעולות mock (API calls)
- **תמונות**: רק תמונות מקומיות יועתקו ל-assets (לא URLs)
- **טאבים**: טאבים עם `v-show` או `@click` יהפכו למסכים נפרדים
- **פריסה**: הסקריפט מנסה לשמור על הפריסה המקורית ככל האפשר

## 🔍 דוגמה מלאה

```bash
# תיקיית HTMLs
html_files/
├── index.html
├── dashboard.html
└── settings.html

# הרצת הסקריפט
python html_to_zip_converter.py ./html_files

# תוצאה
converted_apps/
├── index/
│   ├── app.json
│   ├── routes.json
│   ├── styles.json
│   ├── actions.json
│   └── screens/
│       └── ...
├── index.zip
├── dashboard/
│   └── ...
├── dashboard.zip
├── settings/
│   └── ...
└── settings.zip
```

## ⚠️ מגבלות

- הסקריפט לא ממיר JavaScript מורכב
- אינטראקציות דינמיות יהפכו לפעולות mock
- CSS מותאם אישית לא תמיד יומר בצורה מושלמת

