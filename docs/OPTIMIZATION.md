# Professional optimallashtirish va Walk-Forward (SMC_AutoTrader)

Bu qo'llanma strategiyani **professional** darajada sinash va sozlash jarayonini beradi.

> ⚠️ **Halol haqiqat:** bu jarayon strategiya foydali bo'lishini **kafolatlamaydi**. Ko'p
> strategiyalar sinovdan o'tolmaydi — bu normal. Maqsad: foydali bo'lsa **topish**, foydasiz
> bo'lsa **tashlab yuborish**. Professional traderlik shundan iborat, "har doim yutish" emas.

---

## 0. Nimani optimallashtiramiz (asosiy tamoyil)

- **M1/M5 EMAS.** Faqat **M15** yoki **H1**. Kichik TF'da SMC ishlamaydi (spread + shovqin).
- Bir vaqtда **4–6 ta** parametrdan ko'p emas — aks holda overfitting va cheksiz vaqt.
- Maqsad: **Net Profit emas**, balki **barqarorlik** (Profit Factor, Recovery, past Drawdown).

---

## 1. Optimallashtiriladigan parametrlar (tavsiya)

MT5 Tester → **«Параметры»** yorlig'iда shu parametrlar yonida katakchani ✅ belgilang
va Start/Step/Stop kiriting:

| Parametr | Start | Step | Stop | Izoh |
|---|---|---|---|---|
| `InpSwing` | 3 | 1 | 10 | Struktura sezgirligi |
| `InpRewardRR` | 1.0 | 0.5 | 3.0 | Risk/Reward |
| `InpADXmin` | 15 | 5 | 30 | Trend-kuch chegarasi |
| `InpZoneBufferATR` | 0.05 | 0.05 | 0.30 | Zona/SL bufer |
| `InpTrailATR` | 1.0 | 0.5 | 2.5 | Trailing masofasi |
| `InpTrendEMA` | 100 | 50 | 250 | Trend EMA |

Qolgan parametrlarni **qotiring** (katakchani bo'sh qoldiring) — preset qiymatida turadi.

> Juda ko'p parametrni birdan optimallashtiribsiz = millionlab kombinatsiya = overfitting.
> Yuqoridagi 6 tasi yetarli. Xohlasangiz avval 3 tasidan boshlang (`InpSwing`, `InpRewardRR`, `InpADXmin`).

---

## 2. Walk-Forward (eng muhim qadam!)

Overfitting'ni aniqlashning yagona ishonchli usuli. Vaqtni **ikkiga** bo'ling:

```
┌─────────────── IN-SAMPLE ───────────────┐  ┌──── OUT-OF-SAMPLE ────┐
│  Optimallashtirish (parametr tanlash)    │  │  Tekshirish (sinov)   │
│  Masalan: 2023.01 – 2024.12              │  │  2025.01 – 2026.07    │
└──────────────────────────────────────────┘  └───────────────────────┘
```

### 2.1 IN-SAMPLE (optimallashtirish)
1. Tester → **«Настройки»**: Символ `XAUUSD`, Период `M15`
2. **Интервал** → `Пользовательский` → **2023.01.01 – 2024.12.31**
3. **Модель** → `1 минута OHLC` (tez) yoki `Каждый тик` (aniq)
4. **«Тип теста»** yonida → **«Генетический алгоритм»** (Генетическая оптимизация)
5. **Критерий** → `Максимум коэффициента восстановления` (Recovery Factor)
   yoki `Комплексный критерий` — **Net Profit'ни tanlaMANG** (overfitting)
6. «Параметры»да yuqoridagi parametrlarni ✅ belgilang
7. **«Старт»** → tugagach natijalar jadvali chiqadi

### 2.2 Eng yaxshi natijani tanlash
Jadvalда **faqat eng yuqori foydani emas**, balki:
- Profit Factor **> 1.3**
- Drawdown **< 25%**
- Savdolar soni **> 100** (kam bo'lsa ishonchsiz)
bo'lgan qatorni tanlang. Ustiga ikki marta bosing → parametrlar yuklanadi.

### 2.3 OUT-OF-SAMPLE (haqiqiy sinov)
1. Endi **Тип теста** → `Одиночный` (oddiy test)
2. **Интервал** → **2025.01.01 – 2026.07.16** (optimallashtirishda ISHLATILMAGAN davr)
3. Parametrlar — 2.2'да tanlanган qiymatlар
4. **«Старт»**

### 2.4 Qaror
- ✅ **Ikkalasида ham** ijobiy (foyda + past DD) → strategiyaда haqiqiy ustunlik bor
- ❌ IN-SAMPLE zo'r, OUT-OF-SAMPLE zarar → **overfitting**, bu sozlama **yaroqsiz**, tashlang

---

## 3. Forward test (demo)

Walk-forward'дан o'tган sozlamani ham darhol real hisобда ishlatmang:
- **DEMO** hisобда **kamida 1 oy** real vaqtда kuzating
- Backtest natijasiga yaqin bo'lsagina — real hisоб (kichik risk)

---

## 4. Realistik kutish

- Optimallashtirishдан keyin ham strategiya **foydasiz** chiqishi mumkin — bu **muvaffaqiyatsizlik emas**, balki foydasiz strategiyani vaqtида aniqlash.
- Professional trader 10 ta strategiyani sinab, 1 tasini topsa — bu yaxshi natija.
- **Grail (har doim yutadigan) yo'q.** Bor deб aytган har kim — aldayapti.

---

## 5. Qisqacha checklist

1. TF tanlang: **M15** yoki **H1** (M1/M5 emas)
2. 3–6 parametrni optimallashtiring (Генетический алгоритм)
3. Kritериy: Recovery Factor (Net Profit emas)
4. IN-SAMPLE'да tanlang → **OUT-OF-SAMPLE'да tekshiring**
5. Ikkalasида ijobiy bo'lsa → **DEMO** forward test (1 oy)
6. Shundagина → real hisоб (kichik risk)
