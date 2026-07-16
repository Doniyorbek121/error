//+------------------------------------------------------------------+
//|                                             SMC_AutoTrader.mq5    |
//|         Smart Money Concepts (Structure + Order Block) auto EA    |
//|                                                                  |
//|  DIQQAT: Bu Expert Advisor real savdo ochadi/yopadi. Foyda       |
//|  kafolati YO'Q. Har doim avval DEMO hisobda sinang.              |
//+------------------------------------------------------------------+
#property copyright "SMC_AutoTrader"
#property version   "1.00"
#property description "Market Structure (BOS) + Order Block retest strategiyasi, risk-menejment bilan."
#property strict

#include <Trade/Trade.mqh>

//====================== KIRISH PARAMETRLARI ========================
input group "=== Umumiy ==="
input long   InpMagic          = 202607;   // Magic raqam
input string InpComment        = "SMC_EA"; // Buyurtma izohi

input group "=== Struktura / Order Block ==="
input int    InpSwing          = 5;        // Swing kuchi (har tomondan bar soni)
input double InpZoneBufferATR  = 0.10;     // Zona/SL bufer (ATR ulushi)
input int    InpAtrPeriod      = 14;       // ATR davri

input group "=== Kirish filtri ==="
input bool   InpUseTrendEMA    = true;     // EMA trend filtri yoqilsinmi
input int    InpTrendEMA       = 200;      // Trend EMA davri
input int    InpMaxSpreadPts   = 30;       // Maksimal spread (punkt); 0 = tekshirilmaydi

input group "=== Savdo vaqti (server vaqti) ==="
input bool   InpUseSession     = false;    // Vaqt filtri yoqilsinmi
input int    InpStartHour      = 7;        // Boshlanish soati
input int    InpEndHour        = 21;       // Tugash soati

input group "=== Risk-menejment ==="
input double InpRiskPercent    = 1.0;      // Har savdoda risk (% balans)
input double InpFixedLot       = 0.0;      // >0 bo'lsa risk o'rniga qat'iy lot
input double InpRewardRR       = 2.0;      // Take Profit = RR x risk masofasi
input double InpMinStopATR     = 0.5;      // Minimal SL masofasi (ATR ulushi)

input group "=== Pozitsiyani boshqarish ==="
input bool   InpUseBreakEven   = true;     // Break-even yoqilsinmi
input double InpBEtriggerR     = 1.0;      // BE ishga tushishi (R foyda)
input double InpBElockPts      = 5;        // BE qulf (punkt)
input bool   InpUseTrailing    = true;     // Trailing stop yoqilsinmi
input double InpTrailATR       = 1.0;      // Trailing masofasi (ATR ulushi)

input group "=== Vizual (zonalarni chizish) ==="
input bool   InpDrawZones      = true;     // Zonalarni grafikda chizish
input color  InpBullZoneColor  = clrTeal;  // Bull (demand) zona rangi
input color  InpBearZoneColor  = clrCrimson; // Bear (supply) zona rangi
input color  InpRetestColor    = clrGold;  // Retest bo'lgan zona rangi
input int    InpZoneExtendBars = 30;       // Zonani o'ngga uzaytirish (bar)
input int    InpMaxDrawZones   = 12;       // Grafikda saqlanadigan zonalar soni
input bool   InpZoneFill       = true;     // Zonani to'ldirish (fon)

//====================== GLOBAL O'ZGARUVCHILAR =====================
CTrade   trade;
int      hAtr   = INVALID_HANDLE;
int      hEma   = INVALID_HANDLE;

datetime lastBarTime = 0;

// oxirgi tasdiqlangan swinglar
double   swHighPrice = 0.0,  swLowPrice = 0.0;
double   swHighHi = 0.0, swHighLo = 0.0;   // swing high candle range
double   swLowHi  = 0.0, swLowLo  = 0.0;   // swing low candle range
datetime swHighTime = 0, swLowTime = 0;    // swing shami vaqti (chizish uchun)
bool     haveSH = false, haveSL = false;

// faol zona
int      trendDir   = 0;      // 1 = bull, -1 = bear, 0 = yo'q
bool     zoneActive = false;
double   zoneHi = 0.0, zoneLo = 0.0;
bool     zoneTraded = false;

// chizilgan zona obyektlari
string   zoneNames[];         // grafikdagi rectangle nomlari
long     zoneCounter = 0;     // noyob nom uchun sanagich
string   ZONE_PREFIX = "SMC_ZONE_";
string   activeZoneName = ""; // hozirgi faol zona obyekti
bool     zoneRetested = false;// faol zona retest bo'ldimi

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetDeviationInPoints(20);

   hAtr = iATR(_Symbol, _Period, InpAtrPeriod);
   if(InpUseTrendEMA)
      hEma = iMA(_Symbol, _Period, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);

   if(hAtr == INVALID_HANDLE || (InpUseTrendEMA && hEma == INVALID_HANDLE))
     {
      Print("Indikator handllarini yaratib bo'lmadi.");
      return(INIT_FAILED);
     }

   if(InpRiskPercent <= 0 && InpFixedLot <= 0)
      Print("Ogohlantirish: Risk% va Fixed lot ikkalasi ham 0. Savdo ochilmaydi.");

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(hAtr != INVALID_HANDLE) IndicatorRelease(hAtr);
   if(hEma != INVALID_HANDLE) IndicatorRelease(hEma);
   DeleteAllZones();
  }
//+------------------------------------------------------------------+
//| Zonani grafikda chizish (rectangle)                              |
void DrawZone(bool isBull, double hi, double lo, datetime t0)
  {
   if(!InpDrawZones) return;
   string name = ZONE_PREFIX + IntegerToString(zoneCounter++);
   datetime t1 = TimeCurrent() + (datetime)(InpZoneExtendBars * PeriodSeconds(_Period));
   color c = isBull ? InpBullZoneColor : InpBearZoneColor;

   if(ObjectCreate(0, name, OBJ_RECTANGLE, 0, t0, hi, t1, lo))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, c);
      ObjectSetInteger(0, name, OBJPROP_FILL, InpZoneFill);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

      int n = ArraySize(zoneNames);
      ArrayResize(zoneNames, n + 1);
      zoneNames[n] = name;
      activeZoneName = name;
      zoneRetested   = false;
      PruneZones();
      ChartRedraw(0);
     }
  }
//+------------------------------------------------------------------+
//| Faol zona retest bo'lsa (narx tegsa) rangini o'zgartirish        |
void CheckRetest()
  {
   if(!InpDrawZones || zoneRetested || !zoneActive) return;
   if(activeZoneName == "" || ObjectFind(0, activeZoneName) < 0) return;

   double l1 = iLow(_Symbol, _Period, 1);
   double h1 = iHigh(_Symbol, _Period, 1);

   // oxirgi yopilgan bar zonaga tegdimi
   if(l1 <= zoneHi && h1 >= zoneLo)
     {
      ObjectSetInteger(0, activeZoneName, OBJPROP_COLOR, InpRetestColor);
      zoneRetested = true;
      ChartRedraw(0);
     }
  }
//+------------------------------------------------------------------+
//| Eng eski zonalarni cheklovdan oshsa o'chirish                    |
void PruneZones()
  {
   while(ArraySize(zoneNames) > InpMaxDrawZones && ArraySize(zoneNames) > 0)
     {
      ObjectDelete(0, zoneNames[0]);
      for(int i = 0; i < ArraySize(zoneNames) - 1; i++)
         zoneNames[i] = zoneNames[i + 1];
      ArrayResize(zoneNames, ArraySize(zoneNames) - 1);
     }
  }
//+------------------------------------------------------------------+
//| Barcha zona obyektlarini o'chirish                               |
void DeleteAllZones()
  {
   for(int i = ArraySize(zoneNames) - 1; i >= 0; i--)
      ObjectDelete(0, zoneNames[i]);
   ArrayResize(zoneNames, 0);
   ObjectsDeleteAll(0, ZONE_PREFIX); // qolgan izlarni ham tozalash
  }
//+------------------------------------------------------------------+
//| Faol zona chizig'ini o'ngga uzaytirish (yangi barlarda)          |
void ExtendLastZone()
  {
   int n = ArraySize(zoneNames);
   if(n == 0) return;
   string name = zoneNames[n - 1];
   datetime t1 = TimeCurrent() + (datetime)(InpZoneExtendBars * PeriodSeconds(_Period));
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t1);
  }
//+------------------------------------------------------------------+
double GetAtr()
  {
   double a[];
   if(CopyBuffer(hAtr, 0, 1, 1, a) < 1) return(0.0);
   return(a[0]);
  }
double GetEma()
  {
   if(!InpUseTrendEMA) return(0.0);
   double e[];
   if(CopyBuffer(hEma, 0, 1, 1, e) < 1) return(0.0);
   return(e[0]);
  }
//+------------------------------------------------------------------+
//| shift dagi bar swing high mi?                                    |
bool IsSwingHigh(int shift)
  {
   double h = iHigh(_Symbol, _Period, shift);
   for(int i = 1; i <= InpSwing; i++)
     {
      if(iHigh(_Symbol, _Period, shift + i) >= h) return(false);
      if(iHigh(_Symbol, _Period, shift - i) >= h) return(false);
     }
   return(true);
  }
bool IsSwingLow(int shift)
  {
   double l = iLow(_Symbol, _Period, shift);
   for(int i = 1; i <= InpSwing; i++)
     {
      if(iLow(_Symbol, _Period, shift + i) <= l) return(false);
      if(iLow(_Symbol, _Period, shift - i) <= l) return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| bizning pozitsiyamiz bormi                                       |
bool HasPosition()
  {
   if(!PositionSelect(_Symbol)) return(false);
   return(PositionGetInteger(POSITION_MAGIC) == InpMagic);
  }
//+------------------------------------------------------------------+
//| risk asosida lot hisoblash                                       |
double CalcLots(double slDistance)
  {
   if(InpFixedLot > 0.0)
      return(NormalizeLots(InpFixedLot));
   if(InpRiskPercent <= 0.0 || slDistance <= 0.0)
      return(0.0);

   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * InpRiskPercent / 100.0;
   double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0.0 || tickSize <= 0.0) return(0.0);

   double lossPerLot = slDistance / tickSize * tickVal;
   if(lossPerLot <= 0.0) return(0.0);

   return(NormalizeLots(riskMoney / lossPerLot));
  }
double NormalizeLots(double lots)
  {
   double minL  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(stepL <= 0.0) stepL = 0.01;
   lots = MathFloor(lots / stepL) * stepL;
   lots = MathMax(minL, MathMin(maxL, lots));
   return(lots);
  }
//+------------------------------------------------------------------+
//| filtrlar                                                         |
bool SpreadOK()
  {
   if(InpMaxSpreadPts <= 0) return(true);
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return(spread <= InpMaxSpreadPts);
  }
bool SessionOK()
  {
   if(!InpUseSession) return(true);
   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   if(InpStartHour <= InpEndHour)
      return(t.hour >= InpStartHour && t.hour < InpEndHour);
   return(t.hour >= InpStartHour || t.hour < InpEndHour); // tunni qamrab olsa
  }
//+------------------------------------------------------------------+
//| strukturani yangilash va zonani aniqlash                         |
void UpdateStructure()
  {
   int s = InpSwing; // tekshiriladigan bar (har tomonda InpSwing bar bor)

   // yangi swing high
   if(IsSwingHigh(s))
     {
      swHighPrice = iHigh(_Symbol, _Period, s);
      swHighHi    = iHigh(_Symbol, _Period, s);
      swHighLo    = iLow(_Symbol, _Period, s);
      swHighTime  = iTime(_Symbol, _Period, s);
      haveSH = true;
     }
   // yangi swing low
   if(IsSwingLow(s))
     {
      swLowPrice = iLow(_Symbol, _Period, s);
      swLowHi    = iHigh(_Symbol, _Period, s);
      swLowLo    = iLow(_Symbol, _Period, s);
      swLowTime  = iTime(_Symbol, _Period, s);
      haveSL = true;
     }

   double lastClose = iClose(_Symbol, _Period, 1); // oxirgi yopilgan bar

   // Bullish BOS: oxirgi yopilgan bar swing high dan yuqori yopildi
   if(haveSH && lastClose > swHighPrice)
     {
      trendDir   = 1;
      if(haveSL)
        {
         zoneHi = swLowHi;
         zoneLo = swLowLo;
         zoneActive = true;
         zoneTraded = false;
         DrawZone(true, zoneHi, zoneLo, swLowTime);
        }
      haveSH = false; // shu breakni qayta ishlatmaslik uchun
     }
   // Bearish BOS
   if(haveSL && lastClose < swLowPrice)
     {
      trendDir   = -1;
      if(haveSH)
        {
         zoneHi = swHighHi;
         zoneLo = swHighLo;
         zoneActive = true;
         zoneTraded = false;
         DrawZone(false, zoneHi, zoneLo, swHighTime);
        }
      haveSL = false;
     }
  }
//+------------------------------------------------------------------+
//| kirishni tekshirish                                              |
void CheckEntry()
  {
   if(!zoneActive || zoneTraded) return;
   if(HasPosition())            return;
   if(!SpreadOK() || !SessionOK()) return;

   double atr = GetAtr();
   if(atr <= 0.0) return;
   double buf = atr * InpZoneBufferATR;

   double o1 = iOpen(_Symbol, _Period, 1);
   double c1 = iClose(_Symbol, _Period, 1);
   double l1 = iLow(_Symbol, _Period, 1);
   double h1 = iHigh(_Symbol, _Period, 1);

   double ema = GetEma();
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- BULL: demand zonaga qaytib, bullish tasdiq shami
   if(trendDir == 1)
     {
      bool trendOk = !InpUseTrendEMA || c1 > ema;
      bool touched = (l1 <= zoneHi + buf); // narx zonaga tegdi
      bool confirm = (c1 > o1);            // bullish tasdiq
      if(trendOk && touched && confirm)
        {
         double sl = zoneLo - buf;
         double minStop = atr * InpMinStopATR;
         if(ask - sl < minStop) sl = ask - minStop;
         double slDist = ask - sl;
         if(slDist <= 0) return;
         double tp = ask + slDist * InpRewardRR;

         double lots = CalcLots(slDist);
         if(lots <= 0) return;

         sl = NormalizePrice(sl);
         tp = NormalizePrice(tp);
         if(trade.Buy(lots, _Symbol, 0.0, sl, tp, InpComment))
            zoneTraded = true;
        }
     }
   //--- BEAR: supply zonaga qaytib, bearish tasdiq shami
   else if(trendDir == -1)
     {
      bool trendOk = !InpUseTrendEMA || c1 < ema;
      bool touched = (h1 >= zoneLo - buf);
      bool confirm = (c1 < o1);
      if(trendOk && touched && confirm)
        {
         double sl = zoneHi + buf;
         double minStop = atr * InpMinStopATR;
         if(sl - bid < minStop) sl = bid + minStop;
         double slDist = sl - bid;
         if(slDist <= 0) return;
         double tp = bid - slDist * InpRewardRR;

         double lots = CalcLots(slDist);
         if(lots <= 0) return;

         sl = NormalizePrice(sl);
         tp = NormalizePrice(tp);
         if(trade.Sell(lots, _Symbol, 0.0, sl, tp, InpComment))
            zoneTraded = true;
        }
     }
  }
//+------------------------------------------------------------------+
double NormalizePrice(double p)
  {
   return(NormalizeDouble(p, _Digits));
  }
//+------------------------------------------------------------------+
//| ochiq pozitsiyani boshqarish: break-even + trailing              |
void ManagePosition()
  {
   if(!HasPosition()) return;
   if(!InpUseBreakEven && !InpUseTrailing) return;

   double atr = GetAtr();
   if(atr <= 0.0) return;

   long   type   = PositionGetInteger(POSITION_TYPE);
   double open   = PositionGetDouble(POSITION_PRICE_OPEN);
   double curSL  = PositionGetDouble(POSITION_SL);
   double curTP  = PositionGetDouble(POSITION_TP);
   double point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // dastlabki risk masofasi (open dan SL gacha)
   double riskDist = MathAbs(open - curSL);
   double newSL    = curSL;

   if(type == POSITION_TYPE_BUY)
     {
      double profit = bid - open;
      // break-even
      if(InpUseBreakEven && riskDist > 0 && profit >= riskDist * InpBEtriggerR)
        {
         double be = open + InpBElockPts * point;
         if(be > newSL) newSL = be;
        }
      // trailing
      if(InpUseTrailing)
        {
         double tr = bid - atr * InpTrailATR;
         if(tr > newSL) newSL = tr;
        }
      newSL = NormalizePrice(newSL);
      if(newSL > curSL && newSL < bid)
         trade.PositionModify(_Symbol, newSL, curTP);
     }
   else if(type == POSITION_TYPE_SELL)
     {
      double profit = open - ask;
      if(InpUseBreakEven && riskDist > 0 && profit >= riskDist * InpBEtriggerR)
        {
         double be = open - InpBElockPts * point;
         if(curSL == 0.0 || be < newSL) newSL = be;
        }
      if(InpUseTrailing)
        {
         double tr = ask + atr * InpTrailATR;
         if(curSL == 0.0 || tr < newSL) newSL = tr;
        }
      newSL = NormalizePrice(newSL);
      if((curSL == 0.0 || newSL < curSL) && newSL > ask)
         trade.PositionModify(_Symbol, newSL, curTP);
     }
  }
//+------------------------------------------------------------------+
void OnTick()
  {
   // har tikda ochiq pozitsiyani boshqaramiz (trailing tez ishlashi uchun)
   ManagePosition();

   // struktura/kirish faqat yangi bar yopilganda
   datetime bt = iTime(_Symbol, _Period, 0);
   if(bt == lastBarTime) return;
   lastBarTime = bt;

   if(Bars(_Symbol, _Period) < InpTrendEMA + InpSwing + 10) return;

   UpdateStructure();
   CheckRetest();
   CheckEntry();
   if(InpDrawZones) ExtendLastZone();
  }
//+------------------------------------------------------------------+
