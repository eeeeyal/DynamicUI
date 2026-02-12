# הוראות התקנה ל-iOS על Mac

## שלב 1: התקן CocoaPods

פתח Terminal ב-Mac והרץ:

```bash
sudo gem install cocoapods
```

אם יש שגיאה, נסה:

```bash
sudo gem install cocoapods --user-install
```

## שלב 2: התקן את התלויות

```bash
cd flutter_app/ios
pod install
cd ../..
```

אם יש שגיאה, נסה:

```bash
cd flutter_app/ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ../..
```

## שלב 3: הרץ את האפליקציה

### אפשרות א': דרך Flutter CLI
```bash
cd flutter_app
flutter devices  # רשימת מכשירים זמינים
flutter run -d ios  # הרץ על מכשיר iOS או סימולטור
```

### אפשרות ב': דרך Xcode
```bash
cd flutter_app/ios
open Runner.xcworkspace
```

ב-Xcode:
1. בחר מכשיר או סימולטור מהתפריט למעלה
2. לחץ על כפתור ה-Play (▶️) או לחץ `Cmd+R`

## שלב 4: הגדר Signing (חובה!)

אם יש שגיאת signing:

1. פתח `Runner.xcworkspace` ב-Xcode
2. בחר את ה-target `Runner` משמאל
3. בחר את ה-Tab `Signing & Capabilities`
4. שנה את ה-Bundle Identifier למשהו ייחודי:
   - למשל: `com.yourname.dynamicUIApp`
5. בחר "Automatically manage signing"
6. בחר את ה-Team שלך (אם יש לך Apple Developer Account)

**אם אין לך Apple Developer Account:**
- תוכל להריץ על סימולטור בלבד
- או להירשם ל-Apple Developer Program (99$ לשנה)

## פתרון בעיות נפוצות

### שגיאת Pods:
```bash
cd flutter_app/ios
rm -rf Pods Podfile.lock .symlinks
pod cache clean --all
pod install
```

### שגיאת Flutter:
```bash
cd flutter_app
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```

### שגיאת Xcode:
- ודא ש-Xcode מעודכן (גרסה 14.0+)
- הרץ: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- הרץ: `sudo xcodebuild -license accept`

## בדיקת התקנה

```bash
# בדוק Flutter
flutter doctor

# בדוק CocoaPods
pod --version

# בדוק Xcode
xcodebuild -version
```

## הערות חשובות

1. **חובה Mac** - בניית iOS דורשת Mac, לא ניתן לבנות מ-Windows
2. **Xcode חובה** - הורד מ-App Store (חינם)
3. **Signing** - צריך Apple ID לפחות (חינם) או Developer Account (99$)
4. **סימולטור** - יכול להריץ על סימולטור ללא Developer Account

## בנייה ל-Production

לבניית IPA ל-App Store:

```bash
cd flutter_app
flutter build ios --release
```

אז ב-Xcode:
1. Product → Archive
2. Distribute App
3. App Store Connect
4. Upload

