# הרצה מהירה של האפליקציה

## הוספת Flutter ל-PATH (לסשן הנוכחי)

בכל פעם שתפתח PowerShell חדש, הרץ:

```powershell
$env:Path += ";C:\src\flutter\bin"
```

## הרצת האפליקציה

```powershell
# עבור לתיקיית האפליקציה
cd flutter_app

# הרץ את האפליקציה
flutter run -d windows
```

## הוספת Flutter ל-PATH באופן קבוע

אם תרצה ש-Flutter יהיה זמין תמיד, הרץ:

```powershell
# כנהלה (Run as Administrator)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", [EnvironmentVariableTarget]::Machine)
```

או השתמש בסקריפט:
```powershell
.\add_flutter_to_path.ps1
```

## טעינת ZIP דוגמה

1. הרץ את האפליקציה
2. לחץ על "Choose Local File"
3. בחר את `example_app_config.zip`
4. האפליקציה תציג את המסכים לפי הקונפיגורציה

## פתרון בעיות

אם Flutter לא מוכר:
```powershell
# הוסף ל-PATH של הסשן הנוכחי
$env:Path += ";C:\src\flutter\bin"

# בדוק שהכל עובד
flutter doctor
```

