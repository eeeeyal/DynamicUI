# 🚀 בניית iOS ללא Mac - מדריך CI/CD

אם אין לך Mac, אתה יכול לבנות אפליקציה לאייפון באמצעות שירותי CI/CD.

## 🎯 אפשרות 1: GitHub Actions (מומלץ!)

### יתרונות:
- ✅ **חינמי** לפרויקטים ציבוריים
- ✅ אינטגרציה מלאה עם GitHub
- ✅ Mac runners מהירים
- ✅ קל להגדרה

### איך זה עובד:

1. **צור repository ב-GitHub** (אם עדיין אין)

2. **Push את הקוד:**
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

3. **ה-workflow כבר מוכן!**
   - הקובץ `.github/workflows/ios-build.yml` כבר נוצר
   - GitHub יבנה אוטומטית בכל push

4. **הרץ ידנית:**
   - לך ל-GitHub → Actions
   - בחר "Build iOS"
   - לחץ "Run workflow"

### תוצאה:
- ה-build יופיע ב-Actions
- תוכל להוריד את ה-`.app` או `.ipa` מה-Artifacts

## 🎯 אפשרות 2: Codemagic (חינמי עד 500 דקות/חודש)

### יתרונות:
- ✅ חינמי עד 500 דקות/חודש
- ✅ UI ידידותי
- ✅ תמיכה מעולה ב-Flutter

### איך זה עובד:

1. **הירשם:** https://codemagic.io
2. **הוסף App:** בחר את ה-repository שלך
3. **הגדר Signing:**
   - הוסף Apple Developer Account
   - Codemagic ייצור certificates אוטומטית
4. **הרץ Build:** לחץ "Start new build"

### קובץ מוכן:
- `flutter_app/codemagic.yaml` כבר מוכן
- Codemagic יזהה אותו אוטומטית

## 🎯 אפשרות 3: Bitrise (חינמי עד 200 דקות/חודש)

### יתרונות:
- ✅ חינמי עד 200 דקות/חודש
- ✅ תמיכה טובה ב-Flutter

### איך זה עובד:

1. **הירשם:** https://bitrise.io
2. **הוסף App:** בחר repository
3. **הרץ Build:** Bitrise יזהה Flutter אוטומטית

## 📋 השוואה:

| שירות | מחיר | דקות חינם | קלות |
|-------|------|-----------|------|
| GitHub Actions | חינמי (public) | ללא הגבלה | ⭐⭐⭐⭐⭐ |
| Codemagic | חינמי | 500/חודש | ⭐⭐⭐⭐ |
| Bitrise | חינמי | 200/חודש | ⭐⭐⭐ |

## 🔧 הגדרת Signing (חובה ל-App Store)

### ל-GitHub Actions:

1. **צור Certificates:**
   - היכנס ל-Apple Developer
   - צור Distribution Certificate
   - הורד את ה-certificate

2. **הוסף Secrets ל-GitHub:**
   - Repository → Settings → Secrets → Actions
   - הוסף:
     - `APPLE_CERTIFICATE` (Base64)
     - `APPLE_CERTIFICATE_PASSWORD`
     - `APPLE_PROVISIONING_PROFILE` (Base64)
     - `APPLE_TEAM_ID`

3. **עדכן את ה-workflow:**
   - ראה `BUILD_IOS_WITHOUT_MAC.md` לדוגמה מלאה

### ל-Codemagic:

1. **הוסף Apple Developer Account:**
   - Settings → Integrations → App Store Connect
   - הוסף את ה-credentials שלך

2. **Codemagic ייצור certificates אוטומטית!**

## 🚀 התחלה מהירה:

### GitHub Actions:

```bash
# 1. Push את הקוד ל-GitHub
git add .
git commit -m "Add iOS build workflow"
git push

# 2. לך ל-GitHub → Actions
# 3. לחץ "Run workflow"
```

### Codemagic:

1. לך ל-https://codemagic.io
2. היכנס עם GitHub
3. בחר את ה-repository
4. לחץ "Start new build"

## 📚 תיעוד נוסף:

- [BUILD_IOS_WITHOUT_MAC.md](../flutter_app/BUILD_IOS_WITHOUT_MAC.md) - מדריך מפורט
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Codemagic Docs](https://docs.codemagic.io)

---

**לסיכום:** השתמש ב-GitHub Actions אם יש לך repository ציבורי, או ב-Codemagic אם אתה צריך פרטי!




