# Spendly — bajarilgan ishlar va arxitektura

Bu fayl loyihada nima qilinganini, nima uchun qilinganini va qayerda
turganini bir joyda saqlaydi. Yangi ish qo'shilganda shu faylga yoziladi.

- Talablar hujjati: [`project.md`](project.md)
- Ishlash qoidalari: [`flutter-cloaude.md`](flutter-cloaude.md)
- O'rnatish qadamlari: [`README.md`](README.md)
- **Dizayn tizimi (qulflangan):** [`DESIGN.md`](DESIGN.md) — foydalanuvchi
  aytmaguncha dizayn o'zgartirilmaydi

---

## 1. Loyiha holati

| | |
|---|---|
| Ilova nomi | **Spendly** (PRD'da PulTrack edi, keyin o'zgartirildi) |
| Package / bundle | `erkinovv.dev.spendly` |
| Firebase loyihasi | `spendly-68d5a` |
| Flutter | 3.44.0 · Dart 3.12 |
| State management | Riverpod **3** (`Notifier`, deprecated `StateProvider` emas) |
| Shrift | Plus Jakarta Sans (`google_fonts`) |
| Ikonkalar | Iconsax (`iconsax_plus`) — Linear, faol holatda Bold. Material Icons ishlatilmaydi |
| Til | Interfeys to'liq o'zbekcha (`Locale('uz')`) |
| Mavzu | Yorug' / Tungi. Sukut — **Yorug'**, tizim rangi olinmaydi |

Tekshirish:

```sh
flutter analyze     # 0 muammo
flutter test        # 115 test
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
  ├─ fullName, birthDate, phoneNumber, profilePhotoBase64
  ├─ companyName, position, employmentStartDate
  ├─ salaryType (fixed | calculated)
  ├─ salaryMin, salaryMax, salaryAmount (= oraliqning o'rtachasi), currency
  ├─ workStartTime, workEndTime, lunchBreakMinutes
  ├─ workDays, salaryPayDay, penaltyEnabled, themeMode, ...
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

### 4.2 Onboarding (18 qadam)
Har savol alohida ekranda:

1. Xush kelibsiz · 2. Ism · 3. Tug'ilgan kun · 4. Telefon · 5. Rasm
6. Ish joyi · 7. Lavozim · 8. Ishga kirgan sana · 9. **Maosh turi**
10. Valyuta · 11. **Maosh oralig'i (slider)** · 12. Ish boshlanishi
13. Ish tugashi · 14. **Tushlik tanaffusi** · 15. Ish kunlari
16. Maosh kuni · 17. **Jarima siyosati** · 18. Tasdiqlash

Ixtiyoriy qadamlar (telefon, rasm, ish joyi, lavozim, ishga kirgan sana)
o'tkazib yuborilishi mumkin. Ma'lumot **faqat oxirgi qadamda** yoziladi —
yarim to'ldirilgan profil qolmaydi. Tugagach `publicProfiles` ham yoziladi.

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

### 4.5 Qarzlar va ovoz moduli
Ilovaning asosiy afzalligi — qarzni **gapirib** yozib qo'yish.

**Butunlay tekin va oflayn.** Nutqni qurilmaning o'z tizimi taniydi
(`speech_to_text`), matnni [`voice_parser.dart`] mahalliy tahlil qiladi.
Hech qanday API kalit, to'lov yoki server so'rovi yo'q — **ovoz
qurilmadan chiqmaydi**.

Parser nimalarni tushunadi:

| Imkoniyat | Misol |
|---|---|
| Lotin va **kirill** alifbo | "Алишердан 30 минг олдим" |
| Raqam so'zlari | "o'n besh ming", "ikki yuz ming" |
| "yarim" | "yarim million" = 500 000, "bir yarim million" = 1 500 000 |
| Qo'shilib yozilgan | "30ming", "5mln" |
| Bo'lingan raqam | "2 500 000" |
| Kelishiklar | -dan, -tan, -ga, -ka, -qa, -ni, -ning, -niki |
| Fe'l shakllari | oldim, olganman, berdim, berganman, berdi, olishdi… |
| Izoh | "50 ming **kitob uchun** berdim" → "Kitob uchun" |
| Ishonch darajasi | 0–100%, ekranda ko'rsatiladi |

Ekranda: mikrofon darajasiga **jonli reaksiya qiladigan to'lqin**
(foydalanuvchi eshitilayotganini ko'radi), jonli matn, qaysi til
ishlatilayotgani, misollar va aniqlik foizi.

Yo'nalish fe'ldan aniqlansa ishonch yuqori; faqat kelishik
qo'shimchasidan taxmin qilinsa ogohlantirish chiqadi. Tasdiqlash ekrani
**har doim** ochiladi (PRD 10.8).

> Pullik AI (Whisper, GPT, Gemini) ataylab ishlatilmadi: pul talab
> qiladi, internet majburiy bo'ladi, javob 1–3 soniya kechikadi va ovoz
> serverga ketadi. Kerak bo'lsa parserni almashtirish kifoya — qolgan
> kod tegilmaydi.

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
Ataylab sodda: dumaloq avatar (bosilsa rasm o'zgaradi), ism va lavozim,
so'ng kartalar. Har bir bo'lim o'z ekranida — bitta ekranga hammasini
tiqishtirish o'qishni qiyinlashtiradi.

| Karta | Nima ochiladi |
|---|---|
| Barcha ma'lumotlar | Shaxsiy / Ish joyi / Maosh / Ish jadvali, har biri tahrirlanadi |
| Davomat | Qo'lda kiritish yoki vaqtni tuzatish |
| Sozlamalar | Mavzu, til, ilova versiyasi |
| Chiqish | Faqat lokal kesh tozalanadi |

**Chiqish** Firestore'dagi hech narsani o'chirmaydi — profil, davomat,
qarzlar va yozishmalar joyida qoladi.

### 4.8 Progress ko'rsatkichlari
`runWithProgress` — saqlash va o'zgartirish paytida foizli oyna.
**Foiz soxta emas:** har bosqich haqiqiy ish birligiga mos keladi
(masalan "Rasm siqilmoqda" → "Firestore'ga yozilmoqda"). Tugagach
tasdiq xabari (snackbar) chiqadi.

### 4.9 Brend
Logo `assets/app-logo.jpg` dan generatsiya qilinadi:
`dart run flutter_launcher_icons`. Android adaptive ikonkada oq "S"
alfa kanal bilan ajratilgan — doiraviy maskada kesilmaydi.

---

### 4.11 Bosh sahifadagi statistika
Halqa (dumaloq) progress + chiziqli barlar, `CustomPainter` bilan —
`fl_chart` kabi paket qo'shilmagan, bitta halqa uchun butun grafik
kutubxonasi ortiqcha.

- Halqa: oy bo'yicha o'tgan ish kunlari nisbati
- **Jami ishlagan vaqt** — butun davr bo'yicha
- Chiziqli barlar: ishlangan soat, davomat, kechikish

Umumiy raqamlar Firestore'ning **aggregate** so'rovi orqali olinadi
(`AttendanceService.fetchTotals`) — hujjatlar yuklanmaydi. Bu muhim:
har bir davomat hujjatida ikkita selfie Base64 sifatida turadi (~300 KB),
oddiy o'qish yuzlab megabayt trafik degani bo'lardi.

### 4.12 Cupertino (yumshoq) ko'rinish
Sana va vaqt tanlash Material dialogidan iOS g'ildiragiga o'tkazildi
(`SoftPickers`) — pastdan chiqadigan varaq, silliq surish. Matn
maydonlarida yumaloq kursor, Cupertino belgilash menyusi va mavzuga mos
klaviatura ko'rinishi. Switch ham Cupertino.

> **Eslatma:** matn klaviaturasining o'zini ilova almashtira olmaydi —
> u tizim IME'si (Gboard va h.k.). Ilova boshqaradigan hamma narsa iOS
> uslubiga keltirilgan.

### 4.13 Dizayn: Liquid Glass (2026-10-03)
To'liq tavsif va qiymatlar — [`DESIGN.md`](DESIGN.md) (**qulflangan**).
Qisqacha:

- **Shaffof oyna** kartalar (`GlassSurface`: yorug'lik gradienti, yaltiroq
  qirra, haqiqiy blur) och yashil/och ko'k doiralar ustida.
- Fon sahifa o'tish mavzusi orqali (`GlassPageTransitionsBuilder`) —
  ekran fayllari fon chizmaydi, `Scaffold` shaffof.
- **Brend qizili** `#EE1C25` (logoga mos); `blue` tokeni nomi tarixiy.
- Yagona **shrift shkalasi** (12–32 px, `context.text.*`), 4 ta **radius**
  (`AppRadius`). 157 ta qo'lda yozilgan o'lcham shkalaga keltirildi.
- **Iconsax** ikonkalari, **Plus Jakarta Sans** shrifti.
- Input: ingichka (0.6) to'liq chegara, och kulrang so'rovli hint,
  telefon formati `+998 90 123 45 67`.
- Onboarding: asosiy tugma eng pastda, "O'tkazib yuborish" uning ostida.

### 4.14 Ish vaqti eslatmalari (lokal bildirishnoma)
Ish kunlari: boshlanishdan 10 daqiqa oldin, boshlanganda va tugaganda.
Keyingi 14 kun rejalashtiriladi (`ReminderPlanner`, sof Dart + testlar).
Check-in qilingan kuni boshlanish eslatmalari, check-out qilinganda
tugash eslatmasi chiqmaydi; dam olish kunlari jim; chiqilganda bekor
qilinadi. Sozlamalar → "Bildirishnomalar" switch. Server/push yo'q —
`flutter_local_notifications`. Davomat oqimiga tegilmagan:
`reminderSyncProvider` `AuthGate`da kuzatiladi.

**Bildirishnomalar tarixi:** Bosh sahifadagi qo'ng'iroqcha → ro'yxat.
Lokal eslatmalarda iOS "ko'rildi" ma'lumotini bermaydi, shuning uchun
rejalashtirilgan eslatma vaqti o'tgach "kelgan" hisoblanadi
(`NotificationHistory`, sof Dart + testlar). Telefonda saqlanadi
(`SharedPreferences`), 30 kun; chiqilganda tozalanadi. Bildirishnoma
tizim sozlamalaridan o'chirilgan bo'lsa ham ro'yxatda ko'rinadi.

---

## 4.10 Maosh algoritmi (2 x 2)

Maosh **turi** va **jarima siyosati** — ikki mustaqil sozlama. Ular birga
to'rt xil holatni beradi:

| Maosh turi | Jarima | Oylik qanday chiqadi |
|---|---|---|
| **Fixed** | yo'q | Kelishilgan summa har oy to'liq |
| **Fixed** | bor | Kelishilgan summa − kechikish jarimasi |
| **Kunlik hisob** | yo'q | Kelgan kunlar x kunlik stavka |
| **Kunlik hisob** | bor | Kelgan kunlar x kunlik stavka − jarimalar |

**Fixed** — ko'p ish joylarida shunday: ishga bormagan kun uchun pul
ushlanmaydi, dam olish kunida ishlasa ham qo'shilmaydi. Bunda kunlik
summa umuman yozilmaydi (`dailyEarning = 0`), oylik summa
`MonthlySummary` darajasida qo'shiladi.

Kechikish va erta ketish **har doim yoziladi** — jarima o'chirilgan
bo'lsa ham. Ular statistikada ko'rinadi, faqat pulga ta'sir qilmaydi.

**Tushlik tanaffusi** ish soatidan ayiriladi va soatlik stavkaga ta'sir
qiladi: 09:00–18:00 + 60 daqiqa tanaffus = 8 soat, ya'ni bir xil kunlik
summa kamroq soatga bo'linadi.

**Maosh oralig'i** — foydalanuvchi min va max kiritadi (slider yoki qo'lda),
hisob-kitobda `UserProfile.averageOf(min, max)` — o'rtachasi ishlatiladi.
Oraliq keyin o'zgarsa ham, `salaryAmount` alohida saqlangani uchun eski
oylar o'z qiymati bilan qoladi.

---

## 5. PRD'dan ataylab chetlanishlar

| Nima | Nega |
|---|---|
| `"oldim"` → `i_owe` (PRD'da `owed_to_me`) | PRD'ning o'zi savol belgisi qo'ygan. Alisherdan pul **olgan** bo'lsam, qarzdor — men. `voice_parser.dart:_detectType` da bir qatorda qaytariladi |
| Gilroy → **Plus Jakarta Sans** | Gilroy tijoriy, Google Fonts'da yo'q. `AppTheme.fontStyle()` da almashtiriladi |
| Ko'k aksent → **brend qizili** `#EE1C25` | Foydalanuvchi qarori: logo bilan bir brend. `blue` tokeni nomi saqlangan |
| Tekis dizayn → **Liquid Glass** | Foydalanuvchi qarori, [`DESIGN.md`](DESIGN.md) |
| Ikonkalar → **Iconsax** | Foydalanuvchi qarori (Figma Community'dagi professional to'plam) |
| Ish vaqti **bildirishnomalari** qo'shildi | Foydalanuvchi so'rovi (PRD'da "kelajakda") |
| `workDays`: 1 = Dushanba … 7 = Yakshanba | PRD "ES6 weekday" degan, lekin `[1..5]` = Dush–Juma Dart'ning `DateTime.weekday` bilan aynan mos |
| Profil `users/{uid}` hujjatining o'zida | Hujjat ichida hujjat bo'lmaydi; PRD 3.3 qoidalari ham shunga mos |
| Mavzuda "System" varianti yo'q | Foydalanuvchi so'rovi: sukut har doim Yorug' |
| `fl_chart` qo'shilmadi | PRD'da "ixtiyoriy", Hisobot ekrani grafik talab qilmaydi |
| **Fixed maosh** turi qo'shildi | PRD faqat kunlik hisobni ko'zda tutgan. Amalda ko'p ish joylarida maosh o'zgarmas — kelmagan kun uchun ushlanmaydi |
| **Maosh oraliq** sifatida so'raladi | Foydalanuvchi so'rovi. Hisobda o'rtachasi ishlatiladi |
| **Tushlik tanaffusi** qo'shildi | Usiz soatlik stavka noto'g'ri chiqardi (9 soat o'rniga aslida 8) |
| **Jarima siyosati** sozlamasi | Ba'zi ish joylarida kechikish uchun pul ushlanmaydi |

---

## 6. Test qoplami

| Fayl | Nimani tekshiradi |
|---|---|
| `test/utils/salary_calculator_test.dart` | Stavkalar, kechikish, erta ketish, jarima chegaralari, tungi smena, nolga bo'lish himoyasi |
| `test/utils/voice_parser_test.dart` | Summa (`30 ming`, `bir million ikki yuz ming`), yo'nalish, ism qo'shimchalari (`-dan`, `-ga`, `-ka`), apostrof variantlari |
| `test/services/chat_service_test.dart` | `chatIdFor` barqarorligi, ishtirokchilar tartibi, avatar bosh harflari |
| `test/widget_test.dart` | Ilova karkasi, sukut mavzu, `uz` lokal, `CustomTheme` (brend rangi) |
| `test/utils/reminder_planner_test.dart` | Eslatmalar: 3 ta vaqt, dam olish kunlari, check-in/out, o'tgan vaqt, tungi smena, ID'lar |
| `test/widgets/phone_formatter_test.dart` | Telefon formati: guruhlash, +998, qisman yozish, o'chirish |
| `test/widgets/app_toast_test.dart` | Toast tepada chiqadi, o'zi yo'qoladi, yangisi eskisini almashtiradi |
| `test/utils/notification_history_test.dart` | Kelgan/kelmagan, qayta rejalashtirish, 30 kun, o'qilmaganlar soni, JSON |

---

## 7. Hali tekshirilmagan

- Ro'yxatdan o'tish → onboarding → check-in oqimi **real qurilmada
  uchidan-uchiga** sinalmagan.
- Kamera, mikrofon va o'zbek tilida nutqni tanish — qo'lda sinash kerak.
- iOS simulator build va ishga tushirish tasdiqlangan (iPhone 16e).
  Android: bildirishnoma uchun manifest/desugaring o'zgarishlari build
  bilan **tekshirilmagan** (foydalanuvchi qarori: faqat iOS).
- Bildirishnomalar real vaqtda kelishi — qo'lda sinash kerak.
- Ichki ekranlar (Bosh sahifa, Hisobot, Qarzlar, Chat, Profil) yangi
  dizaynda skrinshot bilan ko'rilmagan — faqat analyze/test.
