# MT5 Trading Tools

MetaTrader 5 uchun ikkita fayl:

| Fayl | Turi | Vazifasi |
|---|---|---|
| `BuySellSignal.mq5` | **Indikator** | EMA kesishuvi asosida grafikda Buy/Sell strelka signallari (savdo ochmaydi). |
| `SMC_AutoTrader.mq5` | **Expert Advisor (EA)** | Smart Money Concepts strategiyasi bilan **avtomatik** savdo ochadi/yopadi. |
| `presets/SMC_XAUUSD_M15.set` | **Preset** | SMC EA uchun XAUUSD M15 ga sozlangan tayyor parametrlar. |
| `presets/SMC_EURUSD_M15.set` | **Preset** | SMC EA uchun EURUSD M15 ga sozlangan tayyor parametrlar. |

---

## ⚠️ Muhim ogohlantirish (o'qing)

- `SMC_AutoTrader.mq5` — bu **avto-savdo roboti**. U real pul bilan pozitsiya ochadi va yopadi.
- **Hech qanday foyda kafolati YO'Q.** Sifatli kod foydani kafolatlamaydi.
- **Har doim avval DEMO hisobda** kamida bir necha hafta sinang. Faqat natijani tushunib, ishonch hosil qilgandan keyin real hisobga o'tng.
- Standart risk `1%` qilib qo'yilgan — o'zingizga mos sozlang.

---

## SMC_AutoTrader — strategiya

1. **Market Structure** — swing high/low aniqlanadi, narx ularni buzsa (BOS = Break of Structure) trend yo'nalishi belgilanadi.
0. **Multi-timeframe filtri** — savdo faqat **yuqori TF** (masalan H1) trendi bilan **bir yo'nalishda** ochiladi. Yuqori TF trendi HTF EMA'ga nisbatan narx holati bilan aniqlanadi. Bu qarama-qarshi (counter-trend) savdolarni kamaytiradi.
2. **Order Block / zona** — BOS dan oldingi swing shami zona sifatida saqlanadi.
3. **Kirish** — narx trend yo'nalishida shu zonaga qaytib (retest) tasdiq shami bergganda savdo ochiladi.
4. **Chiqish** — SL/TP, ixtiyoriy Break-Even va Trailing Stop.

Aniqlangan **Order Block zonalar** grafikda to'rtburchak (rectangle) sifatida chiziladi —
bull (demand) yashil, bear (supply) qizil. Zonalar o'ngga proyeksiya qilinadi va soni
`InpMaxDrawZones` bilan cheklanadi. Narx zonaga qaytib **teganda (retest)** zona rangi
`InpRetestColor` (oltin) ga o'zgaradi — ishlatilgan zonani darhol ajratib ko'rsatadi.
Narx zonani **qarshi tomonga buzib yopsa (invalidatsiya)** zona `InpBrokenColor`
(kulrang) ga o'zgaradi va u zonaga endi kirilmaydi. Vizualni `InpDrawZones = false`
bilan o'chirsa bo'ladi.

### Info-panel (dashboard)
Grafikning burchagida jonli panel ko'rsatiladi: **Instrument/TF, Trend, Zona holati,
Spread, Pozitsiya, Foyda, Risk, Algo Trading** holati. Har savdo ochilganda grafikda
**kirish strelkasi** chiziladi (yashil = Buy, qizil = Sell).

### Bildirishnoma
Savdo ochilganda va yopilganda **alert** (ekranda) va ixtiyoriy **push** (telefonga)
yuboriladi. Push ishlashi uchun MT5 → Tools → Options → Notifications da MetaQuotes ID
kiritilgan bo'lishi kerak.

### Statistika (tarixdan)
Panel pastida jonli statistika: **umumiy savdolar (W/L), g'alaba %, jami P/L** —
shu EA (magic) va shu instrument bo'yicha tarix bitimlaridan hisoblanadi.

### Kunlik risk limiti
Kun boshidagi equity'ga nisbatan zarar `InpMaxDailyLossPct` (standart 5%) ga yetsa,
kun oxirigacha **yangi savdo ochilmaydi**. Panelda "Kunlik limit: HIT — STOP" ko'rinadi.

### Partial close (TP1)
Narx TP gacha masofaning `InpPartialTPfrac` ulushiga (standart yarim yo'l) yetganda,
pozitsiyaning `InpPartialPct` qismi (standart 50%) yopiladi va qolgani **break-even**'ga
o'tkaziladi hamda trailing bilan yuritiladi.

### Yangilik filtri (faqat live)
`InpUseNewsFilter = true` bo'lsa, MT5 iqtisodiy kalendaridagi **yuqori ta'sirli**
(instrument valyutasiga oid) yangilikdan oldin/keyin belgilangan daqiqalar ichida
yangi savdo ochilmaydi. Iqtisodiy kalendar **Strategy Tester'da ishlamaydi** —
bu filtr faqat real/demo live rejimida ta'sir qiladi.

### Asosiy parametrlar

| Parametr | Izoh | Standart |
|---|---|---|
| `InpRiskPercent` | Har savdoda risk (% balans) | 1.0 |
| `InpFixedLot` | >0 bo'lsa risk o'rniga qat'iy lot | 0.0 |
| `InpRewardRR` | TP = RR × risk masofasi | 2.0 |
| `InpSwing` | Swing kuchi (bar soni) | 5 |
| `InpUseTrendEMA` / `InpTrendEMA` | EMA trend filtri | true / 200 |
| `InpUseMTF` | Yuqori TF trend filtri | true |
| `InpHTF` / `InpHTFema` | Yuqori timeframe va uning EMA davri | H1 / 50 |
| `InpMaxSpreadPts` | Maksimal spread (punkt) | 30 |
| `InpUseBreakEven` / `InpUseTrailing` | Pozitsiyani boshqarish | true / true |
| `InpUsePartial` | TP1 da qisman yopish | true |
| `InpPartialTPfrac` / `InpPartialPct` | TP1 masofasi / yopiladigan hajm % | 0.5 / 50 |
| `InpUseDailyLimit` / `InpMaxDailyLossPct` | Kunlik zarar limiti | true / 5% |
| `InpUseNewsFilter` | Yangilik filtri (faqat live) | false |
| `InpNewsBeforeMin` / `InpNewsAfterMin` | Yangilik oldi/keyingi bufer (daq) | 30 / 30 |
| `InpShowPanel` | Grafikda info-panel (dashboard) | true |
| `InpShowEntryArrows` | Kirish strelkalarini chizish | true |
| `InpAlertPopup` / `InpAlertPush` | Alert / telefonga push | true / false |
| `InpDrawZones` | Zonalarni grafikda chizish | true |
| `InpBullZoneColor` / `InpBearZoneColor` | Zona ranglari | Teal / Crimson |
| `InpRetestColor` | Retest bo'lgan zona rangi | Gold |
| `InpBrokenColor` | Buzilgan (invalid) zona rangi | Gray |
| `InpZoneExtendBars` | Zonani o'ngga uzaytirish (bar) | 30 |
| `InpMaxDrawZones` | Grafikda saqlanadigan zonalar soni | 12 |

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

## Tayyor preset: XAUUSD M15

`presets/SMC_XAUUSD_M15.set` — oltin (XAUUSD) M15 grafigi uchun sozlangan. Oltinning
volatilligini hisobga olib o'zgartirilganlar: `InpMaxSpreadPts=50`, `InpBElockPts=20`,
`InpTrailATR=1.5`, `InpHTF=H1`.

### Qanday yuklash

**Strategy Tester'da:**
1. MT5 → **View → Strategy Tester** → Expert: `SMC_AutoTrader`, Symbol: `XAUUSD`, Period: `M15`.
2. **Inputs** yorlig'i → pastdagi **Load** tugmasi → `SMC_XAUUSD_M15.set` faylini tanlang.

**Jonli grafikda:**
1. EA ni XAUUSD M15 grafigiga tashlang → sozlamalar oynasida **Load** → `.set` faylni tanlang.

> `.set` faylni oson topish uchun uni MT5 → **File → Open Data Folder → MQL5/Presets/**
> papkasiga nusxalang (Tester "Load" oynasi shu papkani ochadi).

> ⚠️ Broker/simvol nomi farq qilishi mumkin (`XAUUSD`, `GOLD`, `XAUUSD.m` ...). O'z brokeringiz
> simvolini tanlang. Preset — **boshlang'ich nuqta**, kafolat emas; avval Tester + DEMO'da sinang.

---

## Tayyor preset: EURUSD M15

`presets/SMC_EURUSD_M15.set` — EURUSD M15 uchun sozlangan. EURUSD 5-xonali (5-digit)
va oltinga qaraganda kamroq volatil bo'lgani uchun o'zgartirilganlar: `InpMaxSpreadPts=20`
(≈2 pip), `InpBElockPts=30` (≈3 pip), `InpTrailATR=1.0`. Yuklash usuli XAUUSD preseti bilan
bir xil (Strategy Tester yoki grafik sozlamasida **Load**).

> Eslatma: 5-xonali brokerda 1 pip = 10 punkt. Shuning uchun oltin va EURUSD presetlarida
> `InpMaxSpreadPts` / `InpBElockPts` qiymatlari **punktda** har xil ko'rinadi, lekin ikkalasi
> ham shu instrumentga mos. SL/TP masofasi ATR asosida bo'lgani uchun avtomatik moslashadi.

---

## Eslatma: TradingView indikatorlari haqida

TradingView (Pine Script) indikatorlarini MT5 ga to'g'ridan-to'g'ri qo'yib bo'lmaydi —
ular boshqa til va platforma. Ularning mantig'ini MQL5 da qaytadan yozish kerak. Bu repodagi
fayllar aynan shunday — MT5 uchun mustaqil yozilgan.
