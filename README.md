# BuySellSignal — MT5 indikatori

MetaTrader 5 uchun **Buy/Sell signal** indikatori. Ikki EMA (tez va sekin)
kesishuvi asosida grafikda strelkalar chizadi va bildirishnoma yuboradi.

## Signal mantig'i

- **Buy (yashil strelka, pastda)** — tez EMA sekin EMAni **pastdan yuqoriga** kesib o'tganda.
- **Sell (qizil strelka, tepada)** — tez EMA sekin EMAni **yuqoridan pastga** kesib o'tganda.

Strelka masofasi ATR asosida hisoblanadi, shuning uchun har qanday instrument/timeframe da to'g'ri joylashadi.

## Kirish parametrlari

| Parametr | Izoh | Standart |
|---|---|---|
| `InpFastPeriod` | Tez EMA davri | 9 |
| `InpSlowPeriod` | Sekin EMA davri | 21 |
| `InpMaMethod` | MA metodi (EMA/SMA/...) | EMA |
| `InpAppliedPrice` | Qo'llaniladigan narx | Close |
| `InpArrowGap` | Strelka masofasi (ATR ulushi) | 1.0 |
| `InpAtrPeriod` | ATR davri | 14 |
| `InpAlertPopup` | Ekranda alert | true |
| `InpAlertPush` | Telefonga push | false |
| `InpAlertEmail` | Email yuborish | false |

## O'rnatish

1. MetaTrader 5 da **File → Open Data Folder** ni bosing.
2. `MQL5/Indicators/` papkasiga `BuySellSignal.mq5` faylini nusxalang.
3. **MetaEditor** da faylni oching va **Compile** (F7) qiling.
4. MT5 da **Navigator → Indicators** dan indikatorni grafikka tashlang.

## Eslatma

Signallar oxirgi **yopilgan bar** da tasdiqlanadi (qayta bo'yalishning oldini olish uchun
bildirishnoma yopilgan barga qarab yuboriladi). Har qanday strategiyani real hisobda
ishlatishdan oldin demo hisobda sinab ko'ring.
