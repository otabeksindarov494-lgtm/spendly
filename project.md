# PulTrack — Shaxsiy Moliya va Ish Vaqti Nazorati Ilovasi

## PROJECT.md — To'liq Texnik Talablar Hujjati (PRD)

---

## 1. LOYIHA HAQIDA UMUMIY MA'LUMOT

**Ilova nomi:** PulTrack

**Platforma:** Flutter (iOS + Android)

**Backend:** Firebase (Authentication, Cloud Firestore, Firestore uchun rasm saqlash — Storage EMAS, rasmlar Base64 yoki Firestore-compatible usulda Firestore'ning o'zida saqlanadi)

**Loyiha maqsadi:** Foydalanuvchining ish joyiga kelish-ketish vaqtini kuzatish (selfie orqali), shu asosda kunlik/oylik maoshni avtomatik hisoblash, kunlik xarajat-daromadlarni yozib borish va do'stlar/tanishlar bilan bo'lgan qarzlarni (ham qo'lda, ham ovoz orqali) boshqarish.

**Asosiy foydalanuvchi:** Bitta shaxs — ilova ko'p foydalanuvchili tizim emas, balki shaxsiy kunlik hayotni raqamlashtirish uchun mo'ljallangan.

---

## 2. DIZAYN TIZIMI (DESIGN SYSTEM)

Ilova quyidagi mavjud `AppTheme` / `CustomTheme` klassidan foydalanadi (fayl loyihaga tayyor holda beriladi — quyidagi struktura AYNAN shu koddan olingan, o'zgartirilmasin):

### Light Theme
| Token | Qiymat | Vazifasi |
|---|---|---|
| `background` | `#FFFFFF` | Kartalar, sahifa foni |
| `inputColor` | `#F7F6FB` | Input maydonlari, scaffold foni |
| `gray` | `#FAFAFA` | Ikkinchi darajali fon |
| `borderGray` | `#EEEEEE` | Chegaralar |
| `textGray` | `#9CA3AF` | Ikkinchi darajali matn |
| `favoriteGray` | `#D9D9D9` | Neytral ikonkalar |
| `bottomNavBg` | `#FFFFFF` | Pastki navigatsiya foni |
| `bottomNavBlue` | `#677294` | Faol bo'lmagan tab ikonkasi |
| `mainDarkBlue` | `#2F2E41` | Asosiy matn, aktiv elementlar |
| `textMainDarkBlue` | `#FFFFFF` | mainDarkBlue ustidagi matn |
| `yellow` | `#FFCC00` | Ogohlantirish, kechikish belgisi |
| `red` | `#F55556` | Xato, qarz (siz qarzsiz), manfiy |
| `blue` | `#3083FF` | Asosiy aksent, tugmalar |
| `green` | `#46E180` | Muvaffaqiyat, ijobiy, "sizdan qarz" |

### Dark Theme
| Token | Qiymat |
|---|---|
| `background` | `#1E1E1E` |
| `inputColor` | `#2A3037` |
| `gray` | `#2A3037` |
| `borderGray` | `#313740` |
| `bottomNavBg` | `#2A3037` |
| `bottomNavBlue` | `#9CA3AF` |
| `mainDarkBlue` | `#FFFFFF` |
| `textMainDarkBlue` | `#2F2E41` |
| `yellow` | `#FFEE02` |
| `red`, `blue`, `green` | Light bilan bir xil |

**Shrift:** Gilroy (butun ilova bo'ylab)

**Muhim eslatma:** `AppTheme` fayli allaqachon tayyor — vibe coding vositasi bu faylni `lib/theme/app_theme.dart` (yoki loyiha strukturasiga mos joyga) sifatida to'g'ridan-to'g'ri ko'chirib qo'yishi kerak, uni qaytadan yozish shart emas. Barcha ekranlar `context.theme.xxx` orqali ranglarga murojaat qilishi kerak.

**Theme almashtirish:** Foydalanuvchi Profil bo'limidan Light/Dark/System rejimlarini tanlay olishi kerak, tanlov `SharedPreferences`'da saqlanadi.

---

## 3. FIREBASE ARXITEKTURASI

### 3.1 Firebase Authentication
- Oddiy telefon raqami yoki email + parol orqali ro'yxatdan o'tish (loyihani soddaligini hisobga olib, **Email/Parol** usuli tavsiya etiladi).
- Bitta foydalanuvchi — lekin kelajakda kengaytirish imkoniyati uchun barcha Firestore hujjatlari `userId` bilan bog'lanadi.

### 3.2 Cloud Firestore — Kolleksiyalar strukturasi

```
users/{userId}
  ├─ profile (document)
  │   ├─ fullName: string
  │   ├─ birthDate: timestamp
  │   ├─ profilePhotoBase64: string        // Firestore ichida saqlanadi
  │   ├─ salaryAmount: number               // masalan 5000000
  │   ├─ currency: string                   // "so'm"
  │   ├─ companyName: string
  │   ├─ workStartTime: string              // "09:00"
  │   ├─ workEndTime: string                // "18:00"
  │   ├─ salaryPayDay: number               // oyning nechinchi kuni (masalan 5)
  │   ├─ workDays: array<int>               // [1,2,3,4,5] (Dush-Juma), ES6 weekday format
  │   ├─ onboardingCompleted: boolean
  │   ├─ themeMode: string                  // "light" | "dark" | "system"
  │   ├─ createdAt: timestamp
  │
  ├─ attendance/{attendanceId} (subcollection)
  │   ├─ date: string                       // "2026-09-02" (YYYY-MM-DD, query oson bo'lishi uchun)
  │   ├─ checkInTime: timestamp | null
  │   ├─ checkOutTime: timestamp | null
  │   ├─ checkInPhotoBase64: string | null
  │   ├─ checkOutPhotoBase64: string | null
  │   ├─ workedHours: number                 // hisoblangan soat (masalan 8.5)
  │   ├─ lateMinutes: number                 // kech qolgan daqiqa
  │   ├─ earlyLeaveMinutes: number           // erta ketgan daqiqa
  │   ├─ penaltyAmount: number               // shu kunlik jarima summasi
  │   ├─ dailyEarning: number                // shu kun uchun ishlab topilgan summa (jarimadan keyin)
  │   ├─ status: string                      // "present" | "absent" | "in_progress"
  │
  ├─ debts/{debtId} (subcollection)
  │   ├─ personName: string
  │   ├─ amount: number
  │   ├─ type: string                        // "i_owe" (men qarzman) | "owed_to_me" (menga qarz)
  │   ├─ description: string | null
  │   ├─ createdVia: string                  // "voice" | "manual"
  │   ├─ isPaid: boolean
  │   ├─ createdAt: timestamp
  │
  ├─ transactions/{transactionId} (subcollection) — ixtiyoriy kengaytma
      ├─ type: string                        // "income" | "expense"
      ├─ amount: number
      ├─ category: string
      ├─ note: string
      ├─ date: timestamp
```

**MUHIM:** Barcha rasmlar (`profilePhotoBase64`, `checkInPhotoBase64`, `checkOutPhotoBase64`) Firebase Storage'da EMAS, balki to'g'ridan-to'g'ri Firestore hujjatlarida Base64 string sifatida saqlanadi. Rasmlar checkIn/checkOut uchun kamera orqali olinganidan so'ng, jo'natishdan oldin siqilishi (compress) kerak — masalan `flutter_image_compress` paketi bilan sifatni pasaytirib, hajmini 200-300 KB atrofida ushlab turish kerak (Firestore hujjat cheklovi 1 MB bo'lgani uchun).

### 3.3 Firestore xavfsizlik qoidalari (misol)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## 4. ONBOARDING OQIMI (Ilovaga birinchi kirish)

Foydalanuvchi ilovaga birinchi marta kirganda, **ketma-ket ekranlar** (PageView yoki alohida Navigator route'lar) orqali quyidagi ma'lumotlar so'raladi. Har bir ekran — bitta savol, "Davom etish" tugmasi bilan, progress indicator (masalan "3/10") yuqorida ko'rsatiladi.

### Onboarding qadamlari (tartib bilan):

1. **Xush kelibsiz ekrani** — ilova haqida qisqa tanishtiruv, "Boshlash" tugmasi
2. **Ism-familiya** — matn kiritish
3. **Tug'ilgan kun** — date picker
4. **Profil rasmi** — kameradan olish yoki galereyadan tanlash (ixtiyoriy, "O'tkazib yuborish" tugmasi bilan)
5. **Oylik maosh miqdori** — raqam kiritish (masalan 5 000 000 so'm), valyuta ko'rsatiladi
6. **Ish boshlanish vaqti** — time picker (default 09:00)
7. **Ish tugash vaqti** — time picker (default 18:00)
8. **Ish kunlari** — hafta kunlarini tanlash (checkbox/chip'lar: Dush, Sesh, Chor, Pay, Jum, Shan, Yak) — default Dush-Juma tanlangan
9. **Maosh beriladigan kun** — oyning nechinchi kuni (1-31 orasidan tanlash, masalan 5-sana)
10. **Yakuniy tasdiqlash ekrani** — barcha kiritilgan ma'lumotlar ro'yxat ko'rinishida ko'rsatiladi, "Tahrirlash" (orqaga qaytish) va "Tasdiqlash va Boshlash" tugmalari

Onboarding tugagach, Firestore'dagi `profile.onboardingCompleted = true` qilib belgilanadi va foydalanuvchi asosiy ilova (bottom navigation) ekraniga yo'naltiriladi. Keyingi kirishlarda onboarding qayta ko'rsatilmaydi (`onboardingCompleted` tekshiriladi).

---

## 5. ASOSIY ILOVA STRUKTURASI — BOTTOM NAVIGATION

4 ta tab:

```
[ 🏠 Bosh sahifa ] [ 📊 Hisobot ] [ 💰 Qarzlar ] [ 👤 Profil ]
```

---

### 5.1-TAB: BOSH SAHIFA (Home)

**Maqsad:** Kunlik check-in/check-out va joriy holatni ko'rsatish.

**Elementlar:**

1. **Yuqori qism — Bugungi holat kartasi:**
   - Bugungi sana
   - Agar hali check-in qilinmagan bo'lsa: katta "Ishga keldim ✅" tugmasi (bosilganda kamera ochiladi, selfie olinadi, vaqt avtomatik yoziladi)
   - Agar check-in qilingan, lekin check-out qilinmagan bo'lsa: "Kelgan vaqt: 09:05" ko'rsatiladi + "Ishdan ketyapman 🚪" tugmasi
   - Agar ikkalasi ham bajarilgan bo'lsa: "Kelgan: 09:05 | Ketgan: 18:10 | Ishladi: 9s 05daq" statistika ko'rinishida

2. **Statistika bloki (kichik kartalar, masalan 2x2 grid):**
   - Bugun ishlagan soat
   - Shu oy jami ishlagan kunlar soni
   - Shu oy jami kechikish (daqiqa)
   - Joriy hisoblangan oylik (jonli, kunlik yangilanadigan)

3. **"Oxirgi 7 kun" bo'limi** — ro'yxat ko'rinishida, har bir kun uchun:
   - Sana (masalan "Dush, 1-sen")
   - Kelgan vaqt / Ketgan vaqt
   - Ishlagan soat
   - Status rangi (yashil = vaqtida, sariq = kechikkan, qizil = kelmagan)
   - Bosilganda shu kunning check-in/check-out rasmlarini ko'rish mumkin (modal/bottom sheet)

**Vizual g'oya:** Yuqorida gradient fon bilan "hero" karta (bugungi holat), pastda oq/kulrang fon ustida ro'yxat — mavjud dizayn tizimidagi `gradient`, `mainDarkBlue`, `blue` ranglaridan foydalaniladi.

---

### 5.2-TAB: HISOBOT (Oylik hisobot)

**Maqsad:** Tanlangan oy bo'yicha to'liq statistika.

**Elementlar:**

1. **Oy tanlash** — yuqorida "< Sentabr 2026 >" ko'rinishidagi navigatsiya (oldingi/keyingi oyga o'tish uchun strelkalar)

2. **Yuqori "hero" karta — Joriy hisoblangan oylik:**
   - Katta shrift bilan: "3 250 000 so'm" (hozirgacha ishlab topilgan, jarimalar ayirilgan holda)
   - Pastda kichik matn: "Belgilangan oylik: 5 000 000 so'm | Jarima: -150 000 so'm"
   - Progress bar (oy necha foizi o'tgani, masalan 15/22 ish kuni)

3. **Statistika kartalari (grid):**
   - Jami ishlangan soat (masalan "142 soat")
   - Jami kelgan kunlar
   - Jami kelmagan kunlar (agar ish kuni bo'lib, kelmagan bo'lsa)
   - Jami kechikish (daqiqa/soat)
   - Jami erta ketish (daqiqa/soat)

4. **Kunlik yozuvlar ro'yxati (to'liq oy uchun):**
   - Har kun uchun karta: sana, kelgan/ketgan vaqt, ishlagan soat, shu kunlik ishlab topilgan summa
   - Har bir yozuvni bosganda check-in va check-out rasmlari katta ko'rinishda ochiladi

**Hisoblash formulasi (muhim):**
```
kunlik_stavka = oylik_maosh / oy_ichidagi_belgilangan_ish_kunlari_soni
soatlik_stavka = kunlik_stavka / (workEndTime - workStartTime soat farqi)

Agar kech kelsa: penaltyAmount += lateMinutes * (soatlik_stavka / 60)
Agar erta ketsa: penaltyAmount += earlyLeaveMinutes * (soatlik_stavka / 60)

dailyEarning = kunlik_stavka - penaltyAmount (agar manfiy bo'lib ketmasin, min 0)

Agar foydalanuvchi ish kuni kelmasa (workDays'ga kiruvchi kun, lekin attendance yozuvi yo'q):
  dailyEarning = 0 (shu kun uchun umuman yozilmaydi/hisoblanmaydi)

Agar dam olish kuni (workDays'ga kirmaydi):
  hisobga olinmaydi, umuman kutilmaydi
```

Oy oxirida: `joriy_hisoblangan_oylik = barcha kunlik dailyEarning'lar yig'indisi`

---

### 5.3-TAB: QARZLAR (Debts)

**Maqsad:** Qarzlarni ovoz orqali yoki qo'lda qo'shish, umumiy balansni ko'rish.

**Elementlar:**

1. **Yuqori xulosa karta (2 ustunli):**
   - Chap: "Sizdan qarz" (owed_to_me yig'indisi) — yashil rang
   - O'ng: "Siz qarzsiz" (i_owe yig'indisi) — qizil rang
   - Pastda: Umumiy sof balans ("Sof holat: +450 000 so'm" yoki "-200 000 so'm")

2. **Qo'shish tugmalari (ikkita variant, masalan FAB yoki ikkita tugma):**
   - 🎤 **Ovoz orqali qo'shish** — mikrofon tugmasi bosiladi, foydalanuvchi gapiradi (masalan: "Alisherdan 30 ming so'm oldim"), mahalliy speech-to-text (o'zbek tili) matnga o'giradi, so'ngra oddiy parsing (regex/keyword asosida) orqali:
     - Ism aniqlanadi (odatda birinchi so'z yoki "dan"/"ga" old qo'shimchasidan oldingi so'z)
     - Summa aniqlanadi ("ming", "million" so'zlarini songa o'giradi: "30 ming" → 30000)
     - Yo'nalish aniqlanadi ("oldim" → menga qarz (owed_to_me, chunki u menga bergan)? yoki "berdim" → men qarzdorman (i_owe)). **Diqqat: bu joyni foydalanuvchi tasdiqlash ekrani orqali tekshirib, kerak bo'lsa tuzatishi kerak** — chunki mahalliy parsing 100% aniq bo'lmasligi mumkin.
     - Tahlildan so'ng natija foydalanuvchiga ko'rsatiladi ("Alisher — 30 000 so'm — Sizdan qarz" ko'rinishida), foydalanuvchi tasdiqlaydi yoki qo'lda tuzatadi, keyin saqlaydi.
   - ✍️ **Qo'lda qo'shish** — oddiy forma: Ism, Summa, Turi (Men qarzdorman / Menga qarz), Izoh (ixtiyoriy)

3. **Qarzlar ro'yxati** — ikki bo'limga ajratilgan yoki filter chip bilan ("Hammasi" / "Sizdan qarz" / "Siz qarzdorsiz"):
   - Har bir karta: ism, summa, sana, izoh, "To'landi" belgisi qo'yish tugmasi (checkbox)
   - Svayp orqali o'chirish imkoniyati

**Ovoz-to-matn texnik yechim:** `speech_to_text` Flutter plagini (device'ning mahalliy nutqni tanish tizimidan foydalanadi, internet talab qilmasligi mumkin, o'zbek tili device sozlamalariga bog'liq — agar device o'zbek tilini qo'llamasa, rus yoki fallback sifatida matn kiritish taklif etiladi).

---

### 5.4-TAB: PROFIL (Profile)

**Elementlar:**

1. **Profil rasmi va ism** — yuqorida, kattaroq ko'rinishda
2. **Shaxsiy ma'lumotlar bo'limi** (onboarding'da so'ralgan barcha ma'lumotlar, tahrirlash mumkin):
   - Tug'ilgan kun
   - Oylik maosh
   - Ish boshlanish/tugash vaqti
   - Ish kunlari
   - Maosh beriladigan kun
   - Har biri bosilganda tahrirlash uchun bottom sheet/modal ochiladi
3. **Sozlamalar bo'limi:**
   - Theme tanlash (Light / Dark / System) — switch yoki segmented control
   - Til (kelajakda kengaytirish uchun, hozircha faqat o'zbek)
4. **Ilova haqida:**
   - Ilova versiyasi (masalan "v1.0.0", `package_info_plus` orqali avtomatik olinadi)
5. **Chiqish (Logout) tugmasi**

---

## 6. TEXNIK STEK (Tavsiya etiladigan Flutter paketlar)

| Vazifa | Paket |
|---|---|
| State management | `flutter_riverpod` yoki `provider` (loyiha kattaligiga mos, riverpod tavsiya etiladi) |
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Kamera | `image_picker` (camera source) |
| Rasm siqish | `flutter_image_compress` |
| Ovozni matnga o'girish | `speech_to_text` |
| Vaqt/sana tanlash | Flutter built-in `showTimePicker`, `showDatePicker` |
| Lokal saqlash (theme, onboarding flag cache) | `shared_preferences` |
| Ilova versiyasi | `package_info_plus` |
| Grafik/statistika (ixtiyoriy) | `fl_chart` |
| Ikonkalar | `lucide_icons` yoki `flutter_svg` |

---

## 7. LOYIHA PAPKA STRUKTURASI (tavsiya)

```
lib/
├─ main.dart
├─ theme/
│   └─ app_theme.dart              // Tayyor kod shu yerga qo'yiladi
├─ models/
│   ├─ user_profile_model.dart
│   ├─ attendance_model.dart
│   └─ debt_model.dart
├─ services/
│   ├─ auth_service.dart
│   ├─ firestore_service.dart
│   ├─ attendance_service.dart      // hisoblash logikasi shu yerda
│   ├─ debt_service.dart
│   └─ speech_service.dart
├─ screens/
│   ├─ onboarding/
│   │   ├─ onboarding_flow.dart
│   │   └─ steps/                  // har bir savol uchun alohida widget
│   ├─ home/
│   │   └─ home_screen.dart
│   ├─ report/
│   │   └─ report_screen.dart
│   ├─ debts/
│   │   └─ debts_screen.dart
│   ├─ profile/
│   │   └─ profile_screen.dart
│   └─ main_navigation.dart         // bottom nav bar container
├─ widgets/
│   ├─ common/                      // qayta ishlatiluvchi komponentlar
│   └─ ...
└─ utils/
    ├─ salary_calculator.dart       // maosh/jarima hisoblash formulalari
    └─ voice_parser.dart            // ovozdan qarz ma'lumotini ajratish
```

---

## 8. ISHLAB CHIQISH BOSQICHLARI (Roadmap)

**1-bosqich — Fundament:**
- Firebase loyihasini sozlash (Auth + Firestore)
- `AppTheme` kodini loyihaga integratsiya qilish
- Login/Register ekranlari

**2-bosqich — Onboarding:**
- 10 qadamli onboarding oqimini yaratish
- Ma'lumotlarni Firestore'ga saqlash

**3-bosqich — Asosiy funksionallik (Home + Attendance):**
- Bottom navigation skeleton
- Check-in/check-out logikasi + kamera integratsiyasi
- Bosh sahifa UI va oxirgi 7 kun ro'yxati

**4-bosqich — Hisoblash mexanizmi:**
- `salary_calculator.dart` — kechikish/erta ketish/kunlik maosh formulalarini implement qilish
- Hisobot (2-tab) UI va ma'lumotlarni bog'lash

**5-bosqich — Qarzlar moduli:**
- Qo'lda qarz qo'shish formasi
- Ovoz orqali qarz qo'shish (`speech_to_text` integratsiyasi + parsing logikasi)
- Qarzlar ro'yxati va balans hisoblash

**6-bosqich — Profil va sozlamalar:**
- Profil tahrirlash
- Theme almashtirish (Light/Dark/System)
- Ilova versiyasi ko'rsatish

**7-bosqich — Cilalash (Polish):**
- Shimmer loading holatlari (`shimmerBase`/`shimmerHighlight` ranglaridan foydalanib)
- Xatoliklarni qayta ishlash (error handling)
- Bo'sh holatlar (empty states) dizayni
- Umumiy UX testlash

---

## 9. KELAJAKDAGI KENGAYTIRISH IMKONIYATLARI (Hozircha kiritilmagan, lekin arxitektura shunga tayyor bo'lishi kerak)

- Kirim-chiqim (transactions) to'liq moduli — Firestore strukturasida joy ajratilgan (`transactions` subcollection)
- Bir nechta ish joyi/smena qo'llab-quvvatlash
- Statistika grafiklari (`fl_chart` bilan oylik trend)
- Push-bildirishnomalar (masalan ishga borish vaqti eslatmasi)
- Ko'p tilli qo'llab-quvvatlash

---

## 10. MUHIM ESLATMALAR (Vibe Coding vositasi uchun)

1. **Rasmlar faqat Firestore'da saqlanadi (Base64 formatda), Firebase Storage ISHLATILMAYDI.** Bu talab qat'iy — foydalanuvchi buni maxsus ta'kidlagan.
2. Rasmlarni Base64'ga o'girishdan oldin albatta siqish (compress) kerak, aks holda Firestore'ning 1 MB hujjat chekloviga tegib qolish mumkin.
3. Barcha ranglar `AppTheme`/`CustomTheme` orqali olinishi kerak, hech qanday rang qattiq kodlanmasin (hardcode qilinmasin).
4. Onboarding faqat bir marta ko'rsatiladi — `profile.onboardingCompleted` maydoni orqali nazorat qilinadi.
5. Kechikish/erta ketish hisob-kitobi `workStartTime`/`workEndTime` bilan solishtirib, daqiqalarda hisoblanadi, so'ngra pul jarimasiga aylantiriladi.
6. Dam olish kunlarida (workDays'ga kirmagan kunlarda) hech qanday hisob-kitob, kutish yoki jarima ishlamaydi.
7. Agar ish kuni bo'lsa-yu, foydalanuvchi kelmasa — shu kun uchun maosh yozilmaydi (kunlik stavka qo'shilmaydi), lekin jarima ham qo'shilmaydi (chunki mutlaqo kelmagan, kechikish emas).
8. Ovoz orqali qarz kiritishda **har doim foydalanuvchiga tasdiqlash ekrani ko'rsatilishi shart** — chunki mahalliy parsing xato qilishi mumkin.

---

*Ushbu hujjat PulTrack ilovasining birinchi versiyasi (v1.0.0) uchun to'liq texnik va funksional talablarni o'z ichiga oladi.*
