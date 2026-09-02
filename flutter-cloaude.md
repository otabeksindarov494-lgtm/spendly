# ENG MUHIM QOIDA — buzilmaslik kafolati

Loyihada allaqachon ishlab turgan har qanday narsa (UI, funksiya, ekran, flow)
— bu MUQADDAS chegara. Men (foydalanuvchi) sendan biror narsani **qo'shishni**
yoki **o'zgartirishni** so'rasam, bu hech qachon boshqa, so'ralmagan joyni
buzish huquqini bermaydi.

Bu qoida boshqa hamma narsadan ustun turadi: tezlik, qulaylik, "shunchaki
ishlashi kerak" degan bahonalardan ham ustun.

---

# 1-BOSQICH: O'zgartirishdan OLDIN — "Nimani buzishim mumkin?"

Har qanday kod o'zgartirishdan oldin, kod yozishni boshlashdan avval, quyidagini
albatta bajar:

1. **O'zgartirilishi kerak bo'lgan faylni to'liq o'qi.** Faqat o'zgaradigan
   qatorni emas — butun faylni, chunki funksiya boshqa joyda qanday
   ishlatilayotganini bilmasdan turib xavfsiz o'zgartirib bo'lmaydi.

2. **Shu funksiya/klass/widget qayerlarda chaqirilayotganini top.** Loyiha
   ichida qidiruv qil (grep/qidirish orqali) — bu funksiyani boshqa qancha
   joy ishlatadi? Agar men buni o'zgartirsam, o'sha joylarning barchasi
   hali ham to'g'ri ishlaydimi?

3. **"Yon ta'sir" ro'yxatini tuz (o'zing uchun, kod yozishdan oldin):**
   - Bu o'zgarish qaysi boshqa ekran/widget/funksiyaga ta'sir qilishi mumkin?
   - State (masalan Provider/Riverpod orqali boshqariladigan holat)
     o'zgarsa, uni "tinglayotgan" boshqa joylar buni kutmasdan qabul
     qilib olib, noto'g'ri render bo'lib qolmaydimi?
   - Agar bu funksiya parametr qabul qiladigan bo'lsa va men uni
     o'zgartirsam — uni chaqirayotgan BARCHA joylar yangi parametrga mos
     yangilanganmi, yoki kompilyatsiya xatosi/runtime xato chiqadimi?

4. **Agar yon ta'sir xavfi yuqori bo'lsa (masalan: umumiy widget, shared
   state, ko'p joyda ishlatiladigan funksiya) — kod yozishdan oldin menga
   qisqacha ayt:** "Bu funksiya X, Y, Z joylarda ham ishlatiladi. Men buni
   o'zgartirsam, ular ham tekshirilishi kerak. Davom etaymi?"

Agar sen bu bosqichni o'tkazib yuborib, to'g'ridan-to'g'ri kod yozsang — bu
xato hisoblanadi, hatto kod "ishlagan" taqdirda ham.

---

# 2-BOSQICH: O'zgartirish paytida — "Faqat kerak bo'lgan narsani o'zgartir"

- **Faqat so'ralgan narsani o'zgartir.** Yo'l-yo'lakay "bu yerda ham
  yaxshilash mumkin edi" deb, so'ralmagan joyларни tozalab/o'zgartirib
  yubormaslik — bu eng ko'p buzilishga sabab bo'ladigan xato. Agar biror
  narsani yaxshilash kerak deb o'ylasang, buni alohida taklif sifatida
  ayt, o'zingcha o'zgartirib qo'ymang.

- **Mavjud funksiya signature'ini (parametrlar, qaytish turi) o'zgartirish
  — bu "kichik o'zgarish" emas.** Bu har doim yuqori xavfli hisoblanadi,
  chunki uni chaqirgan BARCHA joylar buziladi. Bunday o'zgarishni qilishdan
  oldin, buni chaqirayotgan joylarni ham birga yangilash reja qilingan
  bo'lishi shart.

- **UI qatlamida:** Agar bitta widget'ni o'zgartirsang va u boshqa
  ekranlarda ham qayta ishlatilsa (reusable widget) — o'zgarish barcha
  ishlatilgan joylarda vizual/funksional buzilish keltirib chiqarmasligini
  tekshir. Agar bitta ekranga xos o'zgarish kerak bo'lsa-yu, widget umumiy
  bo'lsa — umumiy widget'ni o'zgartirish o'rniga, yangi variant/parametr
  qo'shishni ko'rib chiq.

- **State management'da:** Global yoki umumiy state'ni o'zgartirsang, bu
  state'ga bog'liq BARCHA widget'lar qayta ko'rib chiqilishi kerak —
  ularning barchasi yangi holatni to'g'ri kutib oladimi?

---

# 3-BOSQICH: O'zgartirishdan KEYIN — "Men nimani buzmadim, isbotla"

Kod yozib bo'lgach, javobni menga yubormasdan oldin, MAJBURIY tarzda:

1. **`flutter analyze` ishga tushir va natijani ko'rsat.** Agar xato yoki
   warning chiqsa, ularni tuzatmasdan javobni yakunlama.

2. **Agar loyihada test bor bo'lsa — `flutter test` ishga tushir.** Test
   sinib qolsa, bu signal: sen biror narsani buzgansan. Buni jimgina
   o'tkazib yubormaslik — sinib qolgan testni ko'rsat va tushuntir.

3. **O'zgartirilgan faylni yana bir marta o'qib chiq va o'zingdan so'ra:**
   - Men 1-bosqichda topgan "chaqiruv joylari"ning barchasi hali ham
     to'g'ri ishlaydimi?
   - Import qismida ishlatilmay qolgan narsa yo'qmi, yoki kerakli import
     tushib qolmadimi?
   - Men o'zgartirmagan, lekin shu faylda turgan boshqa funksiyalarga
     tasodifan tegib ketmadimmi?

4. **Javobingda aniq ayt:**
   - Aniq nima o'zgardi (fayl va funksiya darajasida)
   - Nega aynan shu joy o'zgartirildi
   - Tekshirilgan "yon ta'sir" nuqtalari va ularning natijasi ("X joyda
     ham ishlatiladi, tekshirdim — muammo yo'q" yoki "X joyga ham tegish
     kerak edi, shuni ham yangiladim")
   - Agar biror narsani tekshira olmagan bo'lsang (masalan testlar yo'q,
     yoki qo'lda ekran ochib ko'rish kerak) — buni OCHIQ ayt: "Bu
     o'zgarishni [X] ekranida qo'lda tekshirib ko'rishingizni tavsiya
     qilaman, chunki avtomatik test yo'q."

Hech qachon "hammasi ishlaydi" deb ishontirib, tekshirmagan narsani
tekshirilgandek ko'rsatma. Bu eng jiddiy ishonch buzilishi hisoblanadi.

---

# QATTIQ TAQIQLAR

- **Refactor qilishni o'zingcha boshlab yubormaslik.** Men aniq so'ramagan
  bo'lsam, kodni "chiroyliroq" qilish uchun struktura o'zgartirmaysan.
- **Ishlatilmayotgandek ko'ringan kodni o'chirib tashlamaslik**, agar aniq
  ishonchli bo'lmasang. Ishlatilmayotgan deb o'ylagan narsang aslida
  boshqa joydan dinamik chaqirilayotgan bo'lishi mumkin.
- **"Tezroq bo'lishi uchun" tekshiruv bosqichlarini qisqartirib
  yubormaslik.** 1 va 3-bosqichlar har doim bajariladi, hatto vazifa
  "oddiy" ko'ringan taqdirda ham — chunki eng ko'p buzilish aynan
  "bu oddiy o'zgarish" deb o'ylangan joylarda yuz beradi.
- **Xato yoki noaniqlikni yashirmaslik.** Agar biror narsa ishlamasligi
  mumkin, yoki tekshira olmagan bo'lsang — buni sokin o'tkazib yubormay,
  ochiq ayt.

---

# Muloqot uslubi

- Javoblarni **o'zbek tilida** ber.
- Yaltiroq maqtovlarsiz, to'g'ridan-to'g'ri gapir.
- Agar men noto'g'ri yoki xavfli narsa so'rasam (masalan, umumiy
  funksiyani o'ylamasdan o'zgartirishni so'rasam) — buni ayt va nega
  xavfli ekanini tushuntir, keyin men qaror qilayin.
- Har bir javobda: nima o'zgardi, nega, va nimani tekshirding — shu
  uchtasi bo'lishi shart, hajmi kichik bo'lsa ham.

---

# Flutter'ga xos texnik qoidalar

- `const` konstruktorlarni imkon qadar ishlat.
- Business logikani UI widget'laridan ajrat.
- Umumiy (reusable) widget'larni o'zgartirishdan oldin, ularni qaysi
  ekranlar ishlatishini albatta top va sanab o't.
- Yangi paket qo'shishdan oldin `pubspec.yaml`ni tekshir — dublikat
  funksionallik qo'shilmasin.
- Katta ro'yxatlarni `ListView.builder` bilan render qil, hammasini bir
  vaqtda qurmaslik.
- API kalit, token, parollarni hech qachon kodga hardcode qilma.

---

# Git

- Har bir mantiqiy o'zgarish alohida commit — bir committa aloqasiz
  narsalarni aralashtirmaslik. Shunda biror narsa buzilsa, qaysi commit
  sabab bo'lganini tez topish mumkin bo'ladi.
- Katta o'zgarishdan oldin, joriy holat commit qilinganini so'ra — shunda
  biror narsa buzilib qolsa, orqaga qaytarish oson bo'ladi.
