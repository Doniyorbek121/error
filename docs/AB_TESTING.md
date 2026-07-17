# Filtrlarni A/B taqqoslash qo'llanmasi (SMC_AutoTrader)

Bu qo'llanma har bir filtrni **yoqib/o'chirib** Strategy Tester'da sinash va uning
strategiyaga **haqiqiy foydasi bor-yo'qligini** aniqlash usulini o'rgatadi.

> ⚠️ Maqsad — "chiroyli natija" emas, **ishonchli va barqaror** natija topish. Bir filtr
> backtestda foyda oshirsa-yu, lekin bu tasodif bo'lsa, real bozorda ishlamaydi.

---

## 1. Asosiy tamoyil: bir vaqtda faqat BITTA narsani o'zgartiring

A/B testning butun mohiyati shu. Agar bir vaqtda 3 ta filtrni o'zgartirsangiz, natija
yaxshilangani yoki yomonlashgani **qaysi filtr** tufayli ekanini hech qachon bilmaysiz.

- **A (baseline)** — barcha sozlamalar bir xil, sinaladigan filtr **o'chiq**.
- **B (variant)** — faqat o'sha bitta filtr **yoqilgan**. Boshqa hamma narsa aynan A bilan bir xil.
- A va B ni **bir xil** simvol, timeframe, sana oralig'i, deposit va modelda ishga tushiring.

---

## 2. Baseline (asosiy) sozlamani qat'iy belgilang

Har testda o'zgarmaydigan narsalar:

| Sozlama | Tavsiya |
|---|---|
| Symbol | Masalan `XAUUSD` |
| Timeframe | `M15` (yoki `H1`) |
| Sana oralig'i | Kamida **1–2 yil** (ko'p bitim uchun) |
| Deposit | Masalan `10000` USD |
| Leverage | Real hisobingiznikiga o'xshash |
| Modelling | **"Every tick based on real ticks"** (eng aniq) |
| Optimization | **o'chiq** (oddiy single test) |

> Bu qiymatlarni yozib qo'ying — barcha A/B testlarda **aynan shu** ishlatiladi.

---

## 3. Taqqoslanadigan ko'rsatkichlar

Har test tugagach **Backtest** yorlig'idan quyidagilarni jadvalga yozing:

| Ko'rsatkich | Nimaga qaraymiz |
|---|---|
| **Total Net Profit** | Foyda oshdimi |
| **Profit Factor** | > 1.3 va oshgani yaxshi |
| **Max Drawdown %** | **Kamaygani** yaxshi (eng muhim!) |
| **Recovery Factor** | Oshgani yaxshi |
| **Total Trades** | Filtr nechta savdoni kesdi |
| **Win %** | O'zgarish |
| **Expected Payoff** | O'rtacha bitim oshdimi |

**Oltin qoida:** faqat *foyda* emas — **drawdown pasaygan va Profit Factor oshgan** filtr
haqiqatan qimmatli. Foyda biroz kamayib, lekin drawdown ancha pasaysa — bu ko'pincha
**yaxshi** almashuv (barqarorroq).

---

## 4. Test matritsasi (tartib bilan)

Quyidagi ketma-ketlikda sinang. Har qatorda **faqat bitta** o'zgarish.

### Bosqich 0 — Toza baseline
Barcha sifat filtrlarini **o'chiring**, keyin bu natijani "etalon" sifatida saqlang:
```
InpUseADX      = false
InpUseRSI      = false
InpUseMTF      = false
InpMaxDailyTrades = 0
InpCooldownBars   = 0
```
Bu — eng "xom" strategiya. Barcha keyingi testlar shu bilan solishtiriladi.

### Bosqich 1 — MTF (Multi-timeframe)
| Test | O'zgarish | Kutiladigan ta'sir |
|---|---|---|
| A | `InpUseMTF=false` | (baseline) |
| B | `InpUseMTF=true` | Kamroq, lekin yo'nalishga mos savdolar |

### Bosqich 2 — ADX
| Test | O'zgarish |
|---|---|
| A | `InpUseADX=false` |
| B | `InpUseADX=true`, `InpADXmin=20` |
| B2 | `InpADXmin=25` (kuchliroq filtr) |
| B3 | `InpADXmin=15` (yumshoqroq) |

### Bosqich 3 — RSI
| Test | O'zgarish |
|---|---|
| A | `InpUseRSI=false` |
| B | `InpUseRSI=true` (70/30) |
| B2 | `InpRSIbuyMax=65`, `InpRSIsellMin=35` (qat'iyroq) |

### Bosqich 4 — Overtrading nazorati
| Test | O'zgarish |
|---|---|
| A | `InpMaxDailyTrades=0`, `InpCooldownBars=0` |
| B | `InpMaxDailyTrades=5` |
| C | `InpCooldownBars=3` |

### Bosqich 5 — Risk/RR
| Test | O'zgarish |
|---|---|
| A | `InpRewardRR=2.0` |
| B | `InpRewardRR=1.5` (ko'proq TP tegadi, past RR) |
| C | `InpRewardRR=3.0` (kam tegadi, yuqori RR) |

Har bosqichda **eng yaxshi** variantni tanlab, keyingi bosqichga **o'sha tanlangan** qiymat
bilan o'ting (bosqichma-bosqich yig'ib borasiz).

---

## 5. Natijani yozish uchun jadval namunasi

Har test uchun bitta qator to'ldiring:

| Test | O'zgarish | Net Profit | Prof.Factor | Max DD % | Trades | Win % | Xulosa |
|------|-----------|-----------:|------------:|---------:|-------:|------:|--------|
| A0   | baseline  |            |             |          |        |       | etalon |
| B1   | MTF on    |            |             |          |        |       |        |
| B2   | ADX 20    |            |             |          |        |       |        |
| …    |           |            |             |          |        |       |        |

---

## 6. Qanday xulosa chiqarish

Filtr **B** ni **A** bilan solishtirganda:

- ✅ **Yaxshi filtr:** Max DD pasaydi **VA** Profit Factor oshdi (foyda biroz kamaysa ham OK).
- ⚠️ **Shubhali:** faqat Net Profit oshdi, lekin DD ham oshdi — bu ko'proq risk, sifat emas.
- ❌ **Foydasiz:** Profit Factor pasaydi yoki bitim soni juda kamayib (masalan < 30) statistika ishonchsiz bo'lib qoldi.

---

## 7. Muhim ogohlantirishlar

1. **Kam bitim = ishonchsiz.** Filtr bitimlar sonini keskin kamaytirsa (masalan 200 → 20),
   natija chiroyli ko'rinsa ham unga ishonmang — namuna juda kichik.
2. **Overfitting.** Bir sana oralig'ida eng zo'r chiqqan sozlamani **boshqa (yangiroq)
   oraliqda** (out-of-sample) qayta sinang. Ikkalasida ham yaxshi bo'lsagina — haqiqiy.
   - Masalan: **2023–2024** da tanlang, keyin **2025–2026** (eng yangi davr) da tekshiring.
   - Qoida: har doim **eng yangi** ma'lumotni tekshiruvga qoldiring — u real bozorga eng yaqini.
3. **Bitta simvolga moslama.** XAUUSD'da zo'r sozlama EURUSD'da yomon bo'lishi mumkin —
   har simvolni alohida A/B qiling.
4. **Modelling quality.** "Open prices only" tez, lekin noaniq. Yakuniy qarorni
   **real tick** modelida tasdiqlang.
5. **Kod ≠ foyda.** Bu qo'llanma sizga *sinash usulini* beradi; barqaror foydali
   sozlama topilishini kafolatlamaydi. Har doim **DEMO**da yakuniy tekshiruv.

---

## 8. Qisqacha ish tartibi (checklist)

1. Baseline sozlamani qat'iy belgilang (2-bo'lim).
2. Barcha sifat filtrlarini o'chirib, A0 (etalon) natijasini oling.
3. Bittalab filtr yoqing → test → jadvalga yozing.
4. Har bosqichda eng yaxshisini tanlab, keyingisiga o'ting.
5. Yakuniy to'plamni **out-of-sample** oraliqda tasdiqlang.
6. Keyin **DEMO** hisobda real vaqtda kuzating.
