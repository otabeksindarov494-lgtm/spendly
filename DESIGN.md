# Spendly — dizayn tizimi

> **🔒 QULFLANGAN.** Bu hujjatdagi dizayn foydalanuvchi tomonidan
> tasdiqlangan. Hech qanday rang, shrift, o'lcham, radius, ikonka yoki
> joylashuv **foydalanuvchi aniq aytmaguncha o'zgartirilmaydi** — "yaxshiroq
> bo'lardi" degan sabab bilan ham. Taklif bo'lsa — avval so'raladi.
> O'zgarish tasdiqlansa, kod bilan birga shu hujjat ham yangilanadi.

Manba kod: [`lib/theme/app_theme.dart`](lib/theme/app_theme.dart) (tokenlar),
[`lib/widgets/common/glass.dart`](lib/widgets/common/glass.dart) (shisha).
Barcha ranglar faqat `context.theme.*` orqali olinadi — ekranlarda hardcode
qilinmaydi.

---

## 1. Uslub: Liquid Glass (shaffof oyna)

Shaffof "oyna" kartalar — ortidagi fon xiralashib ko'rinadi.

- **Fon** — har bir sahifa ostida `GlassBackground`: neytral gradient +
  rangli doiralar va shakllar. Sahifa fonni `GlassPageTransitionsBuilder`
  orqali oladi (`Scaffold` shaffof) — ekran fayllari fon chizmaydi.
- **Kartalar** — `AppCard` → `GlassSurface`: yuqori-chapdan pastki-o'ngga
  yorug'lik gradienti, yaltiroq gradient qirra, yumshoq soya, haqiqiy blur.
- **Asosiy panellar** — `GlassPanel` (kuchliroq blur): Login formasi,
  Bosh sahifadagi bugungi holat, Hisobotdagi oylik kartasi.
- **Bottom sheet va dialoglar** — oq (shisha emas), ataylab.

### Fon (yorug' rejim)

| Element | Qiymat | Joyi |
|---|---|---|
| Gradient | `#F4F5F9` → `#FBFBFD` → `#EFF1F6` | yuqori-chap → pastki-o'ng |
| Och yashil doira | `#A7F3D0`, 70% | yuqori-o'ng burchak, 260 px, dumaloq |
| Och ko'k doira | `#BAE6FD`, 70% | pastki-chap burchak, 280 px, dumaloq |
| Och yashil-ko'k shakl | `#CFF4EE` | o'ng tomon |
| Oq yorug'lik shakli | `#FFFFFF` | yuqori-chap |

Doiralar markazdan ~60% gacha to'liq rangda, faqat chekkasida so'nadi —
aniq dumaloq. **Qizil, siyohrang, to'q ko'k nurlar ishlatilmaydi.**

### Shisha tokenlari

| Token | Yorug' | Tungi |
|---|---|---|
| `glassFill` (yuqori-chap) | oq 40% | oq 16% |
| `glassFillLow` (pastki-o'ng) | oq 15% | oq 6% |
| `glassBorder` (yaltiroq qirra) | oq 100% | oq 40% |
| `glassEdgeShade` (xira qirra) | `#1B2140` 20% | oq 8% |
| `glassShadow` | `#1B2140` 10%, blur 28 | qora 40% |
| Karta blur | sigma 16 | sigma 16 |

Tungi rejim fon: `#16171B` → `#111215` → `#181A20`, doiralar `#5EEAD4` va
`#7DD3FC` (25%).

---

## 2. Ranglar

| Token | Qiymat | Vazifasi |
|---|---|---|
| `blue` (nomi tarixiy) | `#EE1C25` — **brend qizili** | Tugmalar, faol tab, havolalar, aksentlar |
| `gradient` | `#FF3B42` → `#EE1C25` | Asosiy tugma (yorqindan brendga, to'q bordo yo'q) |
| `mainDarkBlue` | `#2F2E41` | Asosiy matn |
| `textGray` | `#9CA3AF` | Ikkinchi darajali matn |
| `red` | `#F55556` | Xato, manfiy summa |
| `green` | `#46E180` | Muvaffaqiyat, "Sizdan qarz" |
| `yellow` | `#FFCC00` | Kechikish |

Logo: qizil (`#FE0201`) fonda oq kalligrafik "S" — `assets/app-logo.jpg`.

---

## 3. Shrift

**Plus Jakarta Sans** (`google_fonts`). Gilroy — tijoriy, Google Fonts'da
yo'q; litsenziyali fayllar berilsa `AppTheme.fontStyle()` da almashtiriladi.

Yagona shkala — ekranlar `context.text.*` dan oladi. **12 px dan kichik
matn yo'q.** Raqamlar tabular (summa va taymer "sakramaydi").

| Daraja | O'lcham | Vazifasi |
|---|---|---|
| `displaySmall` | 32 w700 | Asosiy sarlavha (Login, Xush kelibsiz), oylik summa |
| `headlineSmall` | 24 w700 | Ekran/savol sarlavhasi |
| `titleLarge` | 20 w700 | Karta ichidagi katta qiymat |
| `titleMedium` | 17 w600 | AppBar, bo'lim sarlavhasi |
| `titleSmall` | 15 w600 | Ro'yxat qatori sarlavhasi |
| `bodyLarge` | 16 w500 | Kiritilgan matn |
| `bodyMedium` | 15 w400 | Oddiy matn, hint, tagsarlavha |
| `bodySmall` | 13 w400 | Ikkinchi darajali matn |
| `labelLarge` | 15 w600 | Tugma yozuvi |
| `labelMedium` | 13 w600 | Input yorlig'i, chip |
| `labelSmall` | 12 w500 | Eng kichik matn |

---

## 4. Radius

Faqat to'rttasi (`AppRadius`): `sm` 12 · `md` 16 · `lg` 22 · `xl` 28.
Tugma va input — `md`; karta — `lg`; bottom sheet va asosiy panel — `xl`.

---

## 5. Ikonkalar

**Iconsax** (`iconsax_plus`, MIT). Oddiy holatda `IconsaxPlusLinear`, faol
tab va to'ldirilgan holatlarda `IconsaxPlusBold`. Bitta ma'no — doim bitta
ikonka. Material Icons ishlatilmaydi.

---

## 6. Komponent qoidalari

### Input (`AppTextField`)
- Shisha gradient fon (qirqilmaydi), chegara **0.6 px**, rangi `textGray` 45%
  — butun aylana bo'ylab to'liq ko'rinadi. Fokusda brend qizili, 1.0 px.
- Hint — **och kulrang** (`textGray` 70%) va **so'rov ko'rinishida**, misol
  emas: "Ism va familiyangiz", "Telefon raqamingiz", "Kompaniya nomi",
  "Lavozimingiz", "Summani kiriting".
- Xato matni qutidan tashqarida, pastida (12 px, qizil).
- Telefon: `UzPhoneFormatter` — yozish paytida `+998 90 123 45 67`.

### Tugma (`AppButton`)
- Asosiy: brend gradienti + qizil yumshoq soya, balandlik 54, radius 16.
- Ikkinchi darajali: shisha to'ldirish, ingichka chegara.

### Tanlov variantlari (onboarding chiplari, kartalari)
- Tanlanmagan: shisha to'ldirish, chegara 0.6 px. Tanlangan: brend qizili.

### Toast (qisqa xabar)
- `AppToast.show(context, matn, isError: ...)` — ekranning **yuqori**
  qismida, status bar ostida; tepadan silliq tushadi, shisha panel,
  ikonka (muvaffaqiyat — yashil belgi, xato — qizil "!"), 2.6 s dan keyin
  yo'qoladi, bosilsa yopiladi. `ScaffoldMessenger.showSnackBar`
  (pastdan chiqadi) ishlatilmaydi.

### Salomlashuv (Bosh sahifa)
- "Assalomu alaykum" ostida ism va yonida 👋 stikeri: "Azizbek 👋".
- O'ng tomonda **qo'ng'iroqcha**: 48 px shisha doira (blur), Iconsax
  `notification`; o'qilmaganlar soni brend qizilidagi nishonda (9 dan
  ko'p — "9+"). Bosilganda "Bildirishnomalar" ekrani.

### Hisobot — kunlik yozuvlar
- Oyning **har bir** kuni (joriy oyda bugungacha): kelgan, "Kelmadi",
  "Dam olish", "Bugun". Yangi kunlar tepada.
- Kun kartasi: sana + holat chipi (Vaqtida — yashil, Kechikdi — sariq,
  Kelmadi — qizil, Ishda — brend, Dam olish/Bugun — kulrang); raqamlar
  (Keldi, Ketdi, Ishladi, Kechikish, Erta ketish, Jarima, Kunlik maosh —
  0 bo'lganlari yashiriladi; fixed maoshda kunlik maosh yo'q); o'ngda
  ikkita 56 px selfi ("Kelgan", "Ketgan").
- Selfi bosilsa — **dialogda** katta, kattalashtirib ko'rish mumkin.

### Bildirishnomalar ekrani
- Shisha kartalar: tur ikonkasi (oldin — sariq `timer_1`, boshlanish —
  qizil `login`, tugash — yashil `logout`), sarlavha, matn, vaqt
  ("09:00", "Kecha, 09:00", "Dush, 1-sen, 09:00"). Yangilari tepada.
- AppBar'da "Tozalash"; bo'sh holat — "Hozircha bildirishnoma yo'q".

### Pastki menyu
- Shisha panel, yuqorida yorug' chiziq; ikki chetdan **12 px** padding.
- Yozuvlar 12 px (faol — w700). Faol ikonka Bold, qolganlari Linear.

---

## 7. Onboarding (18 qadam)

- Har qadam: orqaga strelka, progress bar, `n/18` hisoblagich, savol
  (`headlineSmall`), tagsarlavha (`bodyMedium`), bitta kiritish.
- **Asosiy tugma ekranning eng pastida.** Ixtiyoriy qadamlarda
  "O'tkazib yuborish" asosiy tugmaning **ostida** (shu sabab ular uchun
  asosiy tugma ~48 px yuqoriroq).
- Xush kelibsiz: logo (60), sarlavha `displaySmall`, 3 ta imkoniyat alohida
  shisha kartalarda (ikonka qutisi 52, ikonka 26).

---

## 8. O'zgartirish tartibi

1. Foydalanuvchi o'zgarishni aniq so'raydi (yoki taklifga rozi bo'ladi).
2. Token bo'lsa — faqat `app_theme.dart`da; ekranlarda hardcode qilinmaydi.
3. Kod va **shu hujjat** birga yangilanadi, bitta commit'da.
