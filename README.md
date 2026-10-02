# Spendly

Shaxsiy moliya va ish vaqti nazorati ilovasi (Flutter + Firebase).
To'liq talablar: [`project.md`](project.md). Ishlash qoidalari:
[`flutter-cloaude.md`](flutter-cloaude.md).

## Nima qiladi

- **Davomat** — ishga kelish/ketishni selfie bilan qayd etish
- **Maosh** — kechikish va erta ketish jarimalarini avtomatik hisoblash
- **Hisobot** — oylik statistika va kunlik yozuvlar
- **Qarzlar** — ovoz orqali ("Alisherdan 30 ming oldim") yoki qo'lda kiritish
- **Profil** — sozlamalar, Light/Dark/System mavzu

## Ishga tushirish

### 1. Paketlar

```sh
flutter pub get
```

### 2. Firebase (majburiy)

Ilova Firebase Authentication va Cloud Firestore'ga tayanadi.
`lib/firebase_options.dart` hozircha **shablon** — uni generatsiya qiling:

```sh
dart pub global activate flutterfire_cli
flutterfire configure
```

Firebase konsolida yoqilgan bo'lishi kerak:

- **Authentication** → Sign-in method → **Email/Password**
- **Cloud Firestore** → ma'lumotlar bazasi yaratilgan

Xavfsizlik qoidalarini joylashtiring:

```sh
firebase deploy --only firestore:rules
```

Qoidalar [`firestore.rules`](firestore.rules) faylida — har bir foydalanuvchi
faqat o'z hujjatlarini o'qiy/yoza oladi.

> Firebase sozlanmaguncha ilova crash bo'lmaydi — ochilganda shu qadamlarni
> ko'rsatuvchi ekran chiqadi.

### 3. Ishga tushirish

```sh
flutter run
```

## Ma'lumotlar strukturasi

Profil maydonlari `users/{userId}` hujjatining **o'zida** saqlanadi,
qolganlari — subkolleksiyalar:

```
users/{userId}                 fullName, salaryAmount, workDays, ...
  ├─ attendance/{YYYY-MM-DD}   checkInTime, lateMinutes, dailyEarning, ...
  ├─ debts/{debtId}            personName, amount, type, isPaid, ...
  └─ transactions/{id}         (kelajak uchun ajratilgan)
```

Rasmlar **Firebase Storage'da emas**, Firestore hujjatida Base64 matn
sifatida saqlanadi. Yuborishdan oldin ~220 KB gacha siqiladi
(`ImageService.compressToLimit`), Firestore'ning 1 MB chekloviga
tegib qolmaslik uchun.

`workDays` — `DateTime.weekday` konvensiyasi: **1 = Dushanba … 7 = Yakshanba**.

## Brend, shrift va ikonkalar

- **Logo** — `assets/app-logo.jpg` (manba). Undan generatsiya qilinganlar:
  - `assets/logo.png` — ilova ichida (splash, Login, onboarding)
  - `assets/icon/app_icon.png` — iOS va Android legacy launcher ikonkasi
  - `assets/icon/app_icon_foreground.png` — Android adaptive: oq "S" alfa
    kanal bilan ajratilgan, doiraviy/squircle maskada kesilmaydi
  - `assets/icon/app_icon_background.png` — logoning o'z qizil foni

  Launcher ikonkalarini qayta generatsiya qilish:

  ```sh
  dart run flutter_launcher_icons
  ```

- **Shrift** — [`google_fonts`](https://pub.dev/packages/google_fonts) orqali
  **Plus Jakarta Sans**. PROJECT.md'da Gilroy ko'rsatilgan, lekin u tijoriy shrift va
  Google Fonts'da yo'q; Plus Jakarta Sans unga eng yaqin bepul geometrik shrift.
  Almashtirish uchun `lib/theme/app_theme.dart`dagi `AppTheme.fontStyle()` va
  `AppTheme.fontTextTheme()` metodlarini o'zgartirish kifoya.

- **Ikonkalar** — [`iconsax_plus`](https://pub.dev/packages/iconsax_plus)
  (Iconsax, MIT): `IconsaxPlusLinear.*`, faol holatlar uchun
  `IconsaxPlusBold.*`. Material Icons ishlatilmaydi.

`google_fonts` shriftni birinchi ishga tushirishda internetdan yuklab, keyin
qurilmada keshlaydi. Butunlay oflayn kerak bo'lsa, `.ttf` fayllarni
`assets/fonts/` ga qo'ying, `pubspec.yaml`da ro'yxatdan o'tkazing va
`GoogleFonts.config.allowRuntimeFetching = false` qiling.

## Tekshirish

```sh
flutter analyze
flutter test
```

Testlar bilan qoplangan: maosh/jarima formulalari
(`test/utils/salary_calculator_test.dart`), o'zbekcha ovoz parseri
(`test/utils/voice_parser_test.dart`) va ilova karkasi
(`test/widget_test.dart`).
