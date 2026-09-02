# Spendly — bajarilgan ishlar va arxitektura

Bu fayl loyihada nima qilinganini, nima uchun qilinganini va qayerda
turganini bir joyda saqlaydi. Yangi ish qo'shilganda shu faylga yoziladi.

- Talablar hujjati: [`project.md`](project.md)
- Ishlash qoidalari: [`flutter-cloaude.md`](flutter-cloaude.md)
- O'rnatish qadamlari: [`README.md`](README.md)

---

## 1. Loyiha holati

| | |
|---|---|
| Ilova nomi | **Spendly** (PRD'da PulTrack edi, keyin o'zgartirildi) |
| Package / bundle | `erkinovv.dev.spendly` |
| Firebase loyihasi | `spendly-68d5a` |
| Flutter | 3.44.0 · Dart 3.12 |
| State management | Riverpod **3** (`Notifier`, deprecated `StateProvider` emas) |
| Shrift | Manrope (`google_fonts`) |
| Ikonkalar | Bootstrap Icons (`bootstrap_icons`) — Material Icons ishlatilmaydi |
| Til | Interfeys to'liq o'zbekcha (`Locale('uz')`) |
| Mavzu | Yorug' / Tungi. Sukut — **Yorug'**, tizim rangi olinmaydi |

Tekshirish:

```sh
flutter analyze     # 0 muammo
flutter test        # 59 test
```

---

## 2. Papka tuzilishi

```
lib/
├─ main.dart                  Firebase init + ProviderScope
├─ app.dart                   MaterialApp, mavzu, uz lokalizatsiya
├─ firebase_options.dart      flutterfire configure natijasi
├─ theme/app_theme.dart       CustomTheme (barcha ranglar SHU YERDA)
├─ models/                    Sof Dart, Firestore'ga bog'liq emas
├─ services/                  Firebase bilan ishlash
├─ providers/                 Riverpod
├─ screens/                   Ekranlar
├─ widgets/common/            Qayta ishlatiladigan widgetlar
└─ utils/                     Sof mantiq (to'liq test bilan qoplangan)
```

### Muhim fayllar

| Fayl | Vazifasi |
|---|---|
| `utils/salary_calculator.dart` | Kunlik/soatlik stavka, kechikish va erta ketish jarimasi, oylik yig'ma |
| `utils/voice_parser.dart` | O'zbekcha gapdan ism, summa va qarz yo'nalishini ajratadi |
| `utils/formatters.dart` | O'zbekcha sana va pul formati (`intl` locale kerak emas) |
| `services/attendance_service.dart` | Davomat + hisob-kitob, qo'lda kiritish |
| `services/chat_service.dart` | Foydalanuvchilar ro'yxati va 1:1 suhbat |
| `services/image_service.dart` | Rasm siqish (~220 KB) va avatar uchun kichik nusxa |
| `widgets/common/progress_dialog.dart` | Bosqichli progress oynasi (foiz soxta emas) |

---

## 3. Firestore strukturasi

```
users/{userId}                    SHAXSIY — faqat egasi ko'radi
  ├─ fullName, salaryAmount, workStartTime, workEndTime,
  │  workDays, salaryPayDay, profilePhotoBase64, themeMode, ...
  ├─ attendance/{YYYY-MM-DD}      checkInTime, lateMinutes, dailyEarning, ...
  ├─ debts/{debtId}               personName, amount, type, isPaid, ...
  └─ transactions/{id}            (kelajak uchun ajratilgan)

publicProfiles/{userId}           OCHIQ — kirgan har kim o'qiydi
  └─ fullName, avatarBase64 (~128px), updatedAt

chats/{chatId}                    Faqat ishtirokchilar
  ├─ participants[2], lastMessage, lastMessageAt, lastSenderId
  └─ messages/{messageId}
      └─ participants[2], senderId, text, createdAt,
         replyToId, replyToText, replyToSenderId
```

**Nega `publicProfiles` alohida:** chat ro'yxatida boshqalarning ismi va
avatari kerak. Agar buning uchun `users/{uid}` ochib qo'yilsa, hamma
bir-birining **maoshi, davomati va qarzlarini** ko'rib qolardi. Shuning
uchun ochiq ma'lumot alohida kolleksiyaga chiqarilgan.

Qoidalar: [`firestore.rules`](firestore.rules) →
`firebase deploy --only firestore:rules`

---

## 4. Bajarilgan ishlar

### 4.1 Fundament
- `CustomTheme` — PRD 2-bo'limidagi barcha ranglar `ThemeExtension` sifatida.
  Ekranlarda **hech qanday rang hardcode qilinmagan** (PRD 10.3).
- Login / ro'yxatdan o'tish (Email + parol), parolni tiklash.
- `AuthGate`: kirilmagan → Login, onboarding tugamagan → Onboarding,
  aks holda → asosiy ekran.

### 4.2 Onboarding (10 qadam)
Xush kelibsiz → ism → tug'ilgan kun → rasm → maosh → ish boshlanishi →
ish tugashi → ish kunlari → maosh kuni → tasdiqlash.
Ma'lumot **faqat oxirgi qadamda** yoziladi — yarim to'ldirilgan profil
qolmaydi. Tugagach `publicProfiles` ham yoziladi.

### 4.3 Davomat va maosh
- Check-in / check-out selfie bilan; rasm Firestore'da Base64
  (Storage ISHLATILMAYDI, PRD 10.1).
- Jarima: `(kechikish + erta ketish) daqiqa × soatlik stavka / 60`.
  `dailyEarning` hech qachon manfiy bo'lmaydi.
- Dam olish kunida hisob-kitob yuritilmaydi (PRD 10.6).
- **Qo'lda kiritish** — Profil → Davomat. O'tgan kunlarni qo'shish yoki
  vaqtni to'g'rilash. Saqlashdan oldin natija ko'rsatiladi.

### 4.4 Hisobot
Oy tanlash, joriy hisoblangan oylik, progress bar, statistika kartalari,
kunlik yozuvlar. Yozuvni bosganda check-in/out rasmlari ochiladi.

### 4.5 Qarzlar
- Ovoz orqali: `speech_to_text` → `VoiceParser` → **tasdiqlash formasi**
  (PRD 10.8 bo'yicha majburiy).
- Qo'lda kiritish, filtr, svayp bilan o'chirish, "to'landi" belgisi.

### 4.6 Chat
- Bottom navigation'da alohida tab.
- Ro'yxatda barcha ro'yxatdan o'tgan foydalanuvchilar: ism + avatar.
  Yozishmasi borlar yuqorida, oxirgi xabar va vaqti bilan.
- 1:1 suhbat: xabar puffaklari, kun ajratkichlari (Bugun / Kecha / sana).
- **Javob berish**: xabarni chapga surish yoki uzoq bosish. Javob
  puffak ichida iqtibos sifatida ko'rinadi.
- Uzoq bosish → javob berish / nusxalash / o'chirish (o'zinikini).
- Ro'yxat `reverse: true` — yangi xabar har doim pastda, avtomatik.

### 4.7 Profil
Rasm, ism, ish joyi, tug'ilgan kun, maosh, ish vaqti, ish kunlari,
maosh kuni — hammasi tahrirlanadi. Mavzu tanlash, ilova versiyasi, chiqish.

### 4.8 Progress ko'rsatkichlari
`runWithProgress` — saqlash va o'zgartirish paytida foizli oyna.
**Foiz soxta emas:** har bosqich haqiqiy ish birligiga mos keladi
(masalan "Rasm siqilmoqda" → "Firestore'ga yozilmoqda"). Tugagach
tasdiq xabari (snackbar) chiqadi.

### 4.9 Brend
Logo `assets/app-logo.jpeg` dan generatsiya qilinadi:
`dart run flutter_launcher_icons`. Android adaptive ikonkada oq "S"
alfa kanal bilan ajratilgan — doiraviy maskada kesilmaydi.

---

## 5. PRD'dan ataylab chetlanishlar

| Nima | Nega |
|---|---|
| `"oldim"` → `i_owe` (PRD'da `owed_to_me`) | PRD'ning o'zi savol belgisi qo'ygan. Alisherdan pul **olgan** bo'lsam, qarzdor — men. `voice_parser.dart:_detectType` da bir qatorda qaytariladi |
| Gilroy → **Manrope** | Gilroy tijoriy, Google Fonts'da yo'q. `AppTheme.fontStyle()` da almashtiriladi |
| `workDays`: 1 = Dushanba … 7 = Yakshanba | PRD "ES6 weekday" degan, lekin `[1..5]` = Dush–Juma Dart'ning `DateTime.weekday` bilan aynan mos |
| Profil `users/{uid}` hujjatining o'zida | Hujjat ichida hujjat bo'lmaydi; PRD 3.3 qoidalari ham shunga mos |
| Mavzuda "System" varianti yo'q | Foydalanuvchi so'rovi: sukut har doim Yorug' |
| `fl_chart` qo'shilmadi | PRD'da "ixtiyoriy", Hisobot ekrani grafik talab qilmaydi |

---

## 6. Test qoplami

| Fayl | Nimani tekshiradi |
|---|---|
| `test/utils/salary_calculator_test.dart` | Stavkalar, kechikish, erta ketish, jarima chegaralari, tungi smena, nolga bo'lish himoyasi |
| `test/utils/voice_parser_test.dart` | Summa (`30 ming`, `bir million ikki yuz ming`), yo'nalish, ism qo'shimchalari (`-dan`, `-ga`, `-ka`), apostrof variantlari |
| `test/services/chat_service_test.dart` | `chatIdFor` barqarorligi, ishtirokchilar tartibi, avatar bosh harflari |
| `test/widget_test.dart` | Ilova karkasi, sukut mavzu, `uz` lokal, `CustomTheme` |

---

## 7. Hali tekshirilmagan

- Ro'yxatdan o'tish → onboarding → check-in oqimi **real qurilmada
  uchidan-uchiga** sinalmagan.
- Kamera, mikrofon va o'zbek tilida nutqni tanish — qo'lda sinash kerak.
- iOS build: `pod install` o'tgan, lekin to'liq iOS build qilinmagan
  (Android APK build tasdiqlangan).
