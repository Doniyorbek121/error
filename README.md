# MT5 Trading Tools

MetaTrader 5 uchun ikkita fayl:

| Fayl | Turi | Vazifasi |
|---|---|---|
| `BuySellSignal.mq5` | **Indikator** | EMA kesishuvi asosida grafikda Buy/Sell strelka signallari (savdo ochmaydi). |
| `SMC_AutoTrader.mq5` | **Expert Advisor (EA)** | Smart Money Concepts strategiyasi bilan **avtomatik** savdo ochadi/yopadi. |

---

## ⚠️ Muhim ogohlantirish (o'qing)

- `SMC_AutoTrader.mq5` — bu **avto-savdo roboti**. U real pul bilan pozitsiya ochadi va yopadi.
- **Hech qanday foyda kafolati YO'Q.** Sifatli kod foydani kafolatlamaydi.
- **Har doim avval DEMO hisobda** kamida bir necha hafta sinang. Faqat natijani tushunib, ishonch hosil qilgandan keyin real hisobga o'tng.
- Standart risk `1%` qilib qo'yilgan — o'zingizga mos sozlang.

---

## SMC_AutoTrader — strategiya

1. **Market Structure** — swing high/low aniqlanadi, narx ularni buzsa (BOS = Break of Structure) trend yo'nalishi belgilanadi.
2. **Order Block / zona** — BOS dan oldingi swing shami zona sifatida saqlanadi.
3. **Kirish** — narx trend yo'nalishida shu zonaga qaytib (retest) tasdiq shami bergganda savdo ochiladi.
4. **Chiqish** — SL/TP, ixtiyoriy Break-Even va Trailing Stop.

### Asosiy parametrlar

| Parametr | Izoh | Standart |
|---|---|---|
| `InpRiskPercent` | Har savdoda risk (% balans) | 1.0 |
| `InpFixedLot` | >0 bo'lsa risk o'rniga qat'iy lot | 0.0 |
| `InpRewardRR` | TP = RR × risk masofasi | 2.0 |
| `InpSwing` | Swing kuchi (bar soni) | 5 |
| `InpUseTrendEMA` / `InpTrendEMA` | EMA trend filtri | true / 200 |
| `InpMaxSpreadPts` | Maksimal spread (punkt) | 30 |
| `InpUseBreakEven` / `InpUseTrailing` | Pozitsiyani boshqarish | true / true |

---

## O'rnatish

### Indikator (`BuySellSignal.mq5`)
1. MT5 → **File → Open Data Folder**
2. `MQL5/Indicators/` ga nusxalang
3. MetaEditor da oching → **F7** (Compile)
4. Navigator → Indicators dan grafikga tashlang

### Expert Advisor (`SMC_AutoTrader.mq5`)
1. MT5 → **File → Open Data Folder**
2. `MQL5/Experts/` ga nusxalang
3. MetaEditor da oching → **F7** (Compile)
4. Grafikga tashlang, **Options → Expert Advisors → Allow Algo Trading** yoqilgan bo'lsin
5. Yuqoridagi **Algo Trading** tugmasi yashil bo'lishi kerak

### Test (majburiy)
- MT5 → **View → Strategy Tester** → EA ni tanlang → tarixiy ma'lumotda tekshiring.
- Keyin **DEMO hisobda** real vaqtda kuzating.

---

## Eslatma: TradingView indikatorlari haqida

TradingView (Pine Script) indikatorlarini MT5 ga to'g'ridan-to'g'ri qo'yib bo'lmaydi —
ular boshqa til va platforma. Ularning mantig'ini MQL5 da qaytadan yozish kerak. Bu repodagi
fayllar aynan shunday — MT5 uchun mustaqil yozilgan.
