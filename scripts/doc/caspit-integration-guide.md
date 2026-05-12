# תיעוד ממשקי אשראית EMV - כספית (Caspit)

## סקירה כללית

המסמכים מתארים את הפונקציות ופרמטרי ה-XML לשימוש ב-HTTP או ב-DLL (אותם שמות) ואת תהליך העבודה עם מתג.

---

## עבודה ב-HTTP

ניתן להפעיל את הממשקים ע"י פניה ב-**HTTP POST** בחיבור רשת לכתובת המכשיר **בפורט 80** (ניתן לשינוי גם ל-HTTPS).

- הסבר לפקודות השונות מפורט במסמך "Caspit SmartRetail Solution"
- ראה קובץ "http post example" עם דוגמא לבקשת חיוב

### חשוב
- ברירת מחדל: **פורט 80**
- ניתן לשנות ל-HTTPS
- מומלץ לקבע את הפורט
- כל המסכים הם לפי ברירת המחדל

---

## עבודה עם DLL

### התקנה
- **Setup_CaspitPaymentService_5.12.02.exe** - DLL 5.12 לשילוב בתוכנת הקופה
- כולל טסטר המאפשר לסמלץ את ה-XML-ים השונים
- יש ליצור קשר עם כספית לצורך ההתקנה המתאימה

### דרייבר USB לפינפד
- להורדת התקנה 3.28 לדרייבר USB (לעבודה בחיבור USB אם יידרש):
  https://1drv.ms/u/s!Ava8cwOP57tTiQUDdnHryocYqJzG?e=4zENqS
- **יש להתקין את הדרייבר לפני חיבור המכשיר למחשב**

---

## הגדרות מסוף - LANES 3000

### הגדרות נוכחיות (מאי 2026) - עובד!
- **Terminal ID:** 6314813
- **Terminal No:** 008
- **Full ID:** 6314813-008
- **IP:** 192.168.0.103 (DHCP - עלול להשתנות)
- **Port:** 443
- **Protocol:** HTTP (plain TCP, בלי TLS)
- **Broker:** לא פעיל
- **Caspit Version:** 2.33.8
- **CTEM Version:** 2.55.1

### מצב תקשורת שעובד
- HTTP POST ישירות למסופון
- PTL Header: `^PTL!00#<LLLL>5202` (52=SmartRetail, 02=ECR)
- XML payload עטוף ב-HTTP POST ל-path: `/cashregister/request/{terminalId}/{termNo}`

### קודי שגיאה נפוצים
- `AshStatus: 494` = מספר מסוף שונה (TerminalId לא תואם)
- `AshStatus: 417` = מספר מסוף אינו תקין
- `CaspitInternalError: 1806` = שגיאה פנימית של כספית
- `ResultCode: 10003` = Timeout / חסר תגובה
- `ResultCode: 0` = מאושר!
- **פתרון שגיאות:** ודא Terminal ID ו-TermNo תואמים למה שמופיע על מסך המסופון

---

## פקודות XML

### בדיקת תקשורת (Command 003)
```xml
<Request>
  <Command>003</Command>
  <TerminalId>0880264</TerminalId>
  <TermNo>001</TermNo>
  <RequestId>{unique_id}</RequestId>
</Request>
```

### חיוב (Command 001)
```xml
<Request>
  <Command>001</Command>
  <Mti>100</Mti>
  <TerminalId>0880264</TerminalId>
  <TermNo>001</TermNo>
  <TimeoutInSeconds>90</TimeoutInSeconds>
  <Amount>100</Amount>           <!-- בעגורות -->
  <Currency>376</Currency>       <!-- ILS -->
  <CreditTerms>1</CreditTerms>  <!-- רגיל -->
  <TranType>1</TranType>
  <PanEntryMode>PinPad</PanEntryMode>
  <Xfield>{unique_id}</Xfield>
  <RequestId>{unique_id}</RequestId>
</Request>
```

---

## הערות
- בהמשך יועבר/יוגדר מכשיר עם מספר מסוף מתאים לעבודה עם/בלי מתג
- סקריפט Python לשליחת בקשות: `scripts/caspit_payment.py`
- ממשק בדיקה (HTML): `caspit-test-standalone.html`
