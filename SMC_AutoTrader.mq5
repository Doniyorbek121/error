//+------------------------------------------------------------------+
//|                                             SMC_AutoTrader.mq5    |
//|         Smart Money Concepts (Structure + Order Block) auto EA    |
//|                                                                  |
//|  DIQQAT: Bu Expert Advisor real savdo ochadi/yopadi. Foyda       |
//|  kafolati YO'Q. Har doim avval DEMO hisobda sinang.              |
//+------------------------------------------------------------------+
#property copyright "SMC_AutoTrader"
#property version   "1.10"
#property description "Market Structure (BOS) + Order Block retest; ADX/RSI/MTF filtrlar, risk-menejment."
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

input group "=== Multi-timeframe (yuqori TF filtri) ==="
input bool             InpUseMTF   = true;         // Yuqori TF trend filtri yoqilsinmi
input ENUM_TIMEFRAMES  InpHTF      = PERIOD_H1;    // Yuqori timeframe
input int              InpHTFema   = 50;           // Yuqori TF EMA davri

input group "=== Savdo vaqti (server vaqti) ==="
input bool   InpUseSession     = false;    // Vaqt filtri yoqilsinmi
input int    InpStartHour      = 7;        // Boshlanish soati
input int    InpEndHour        = 21;       // Tugash soati

input group "=== Risk-menejment ==="
input double InpRiskPercent    = 1.0;      // Har savdoda risk (% balans)
input double InpFixedLot       = 0.0;      // >0 bo'lsa risk o'rniga qat'iy lot
input double InpRewardRR       = 2.0;      // Take Profit = RR x risk masofasi
input double InpMinStopATR     = 0.5;      // Minimal SL masofasi (ATR ulushi)
input bool   InpSkipIfOverRisk = true;     // Risk oshsa (min lot > risk) savdoni o'tkazib yuborish

input group "=== Sifat filtrlari (aniqlikni oshirish) ==="
input bool   InpUseADX         = true;     // ADX trend-kuch filtri (chopni chetlab o'tadi)
input int    InpADXperiod      = 14;       // ADX davri
input double InpADXmin         = 20.0;     // Minimal ADX (past = kuchsiz trend)
input bool   InpUseRSI         = true;     // RSI ekstremum filtri
input int    InpRSIperiod      = 14;       // RSI davri
input double InpRSIbuyMax      = 70.0;     // Buy: RSI shundan yuqori bo'lsa kirmaymiz
input double InpRSIsellMin     = 30.0;     // Sell: RSI shundan past bo'lsa kirmaymiz

input group "=== Overtrading nazorati ==="
input int    InpMaxDailyTrades = 5;        // Kunlik maksimal savdo (0 = cheksiz)
input int    InpCooldownBars   = 3;        // Zarardan keyin sovish (bar); 0 = o'chiq

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
input color  InpBrokenColor    = clrGray;  // Buzilgan (invalid) zona rangi
input int    InpZoneExtendBars = 30;       // Zonani o'ngga uzaytirish (bar)
input int    InpMaxDrawZones   = 12;       // Grafikda saqlanadigan zonalar soni
input bool   InpZoneFill       = true;     // Zonani to'ldirish (fon)
input bool   InpShowEntryArrows= true;     // Kirish strelkalarini chizish

input group "=== Panel (dashboard) ==="
input bool             InpShowPanel   = true;               // Info panelni ko'rsatish
input ENUM_BASE_CORNER InpPanelCorner = CORNER_LEFT_UPPER;  // Panel burchagi
input int              InpPanelX      = 12;                 // Panel X masofa (px)
input int              InpPanelY      = 20;                 // Panel Y masofa (px)

input group "=== Bildirishnoma ==="
input bool   InpAlertPopup     = true;     // Ekranda alert
input bool   InpAlertPush      = false;    // Telefonga push (MT5 sozlamasi kerak)

input group "=== Kunlik risk limiti ==="
input bool   InpUseDailyLimit  = true;     // Kunlik zarar limiti yoqilsinmi
input double InpMaxDailyLossPct = 5.0;     // Maksimal kunlik zarar (% kun boshidagi equity)

input group "=== Partial close (TP1) ==="
input bool   InpUsePartial     = true;     // TP1 da qisman yopish yoqilsinmi
input double InpPartialTPfrac  = 0.5;      // TP1 = TP gacha masofaning ulushi (0.5 = yarim yo'l)
input double InpPartialPct     = 50.0;     // TP1 da yopiladigan hajm (%)

input group "=== Yangilik filtri (faqat live) ==="
input bool   InpUseNewsFilter  = false;    // Yuqori ta'sirli yangilik vaqtida savdodan chetlanish
input int    InpNewsBeforeMin  = 30;       // Yangilikdan oldin (daqiqa)
input int    InpNewsAfterMin   = 30;       // Yangilikdan keyin (daqiqa)

input group "=== Statistika ==="
input int    InpStatsHistoryDays = 0;      // Tarix chuqurligi (kun); 0 = butun tarix

//====================== GLOBAL O'ZGARUVCHILAR =====================
CTrade   trade;
int      hAtr    = INVALID_HANDLE;
int      hEma    = INVALID_HANDLE;
int      hHtfEma = INVALID_HANDLE;
int      hAdx    = INVALID_HANDLE;
int      hRsi    = INVALID_HANDLE;
int      htfBias = 0;          // yuqori TF trend: 1 bull, -1 bear, 0 neytral

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
string   ZONE_PREFIX  = "SMC_ZONE_";
string   ARR_PREFIX   = "SMC_ARR_";
string   PANEL_PREFIX = "SMC_PANEL_";
long     arrCounter   = 0;
string   activeZoneName = ""; // hozirgi faol zona obyekti
bool     zoneRetested = false;// faol zona retest bo'ldimi
string   zoneState = "NONE";  // panel uchun: NONE/BULL/BEAR/RETEST/BROKEN
bool     prevHasPos = false;  // pozitsiya yopilishini aniqlash uchun

// statistika (tarixdan)
int      statTrades = 0, statWins = 0, statLosses = 0;
double   statProfit = 0.0;

// kunlik risk
double   dayStartEquity = 0.0;
int      curDay = -1;

// overtrading nazorati
int      dailyTrades = 0;      // shu kun ochilgan savdolar
datetime lossUntil   = 0;      // shu vaqtgacha zarardan keyin sovish

// partial close
bool     partialDone = false; // joriy pozitsiyada TP1 bajarildimi

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetDeviationInPoints(20);

   hAtr = iATR(_Symbol, _Period, InpAtrPeriod);
   if(InpUseTrendEMA)
      hEma = iMA(_Symbol, _Period, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(InpUseMTF)
      hHtfEma = iMA(_Symbol, InpHTF, InpHTFema, 0, MODE_EMA, PRICE_CLOSE);
   if(InpUseADX)
      hAdx = iADX(_Symbol, _Period, InpADXperiod);
   if(InpUseRSI)
      hRsi = iRSI(_Symbol, _Period, InpRSIperiod, PRICE_CLOSE);

   if(hAtr == INVALID_HANDLE || (InpUseTrendEMA && hEma == INVALID_HANDLE) ||
      (InpUseMTF && hHtfEma == INVALID_HANDLE) ||
      (InpUseADX && hAdx == INVALID_HANDLE) ||
      (InpUseRSI && hRsi == INVALID_HANDLE))
     {
      Print("Indikator handllarini yaratib bo'lmadi.");
      return(INIT_FAILED);
     }

   if(InpRiskPercent <= 0 && InpFixedLot <= 0)
      Print("Ogohlantirish: Risk% va Fixed lot ikkalasi ham 0. Savdo ochilmaydi.");

   dayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   curDay = dt.day;
   prevHasPos = HasPosition();
   ComputeStats();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(hAtr != INVALID_HANDLE) IndicatorRelease(hAtr);
   if(hEma != INVALID_HANDLE) IndicatorRelease(hEma);
   if(hHtfEma != INVALID_HANDLE) IndicatorRelease(hHtfEma);
   if(hAdx != INVALID_HANDLE) IndicatorRelease(hAdx);
   if(hRsi != INVALID_HANDLE) IndicatorRelease(hRsi);
   DeleteAllZones();
   DeletePanel();
   ObjectsDeleteAll(0, ARR_PREFIX);
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
      zoneState      = isBull ? "BULL demand" : "BEAR supply";
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
      zoneState = "RETEST";
      ChartRedraw(0);
     }
  }
//+------------------------------------------------------------------+
//| Zona buzilsa (narx zonadan qarshi tomonga yopilsa) kulrang qilish|
void CheckInvalidation()
  {
   if(!zoneActive) return;

   double c1 = iClose(_Symbol, _Period, 1); // oxirgi yopilgan bar

   bool broken = false;
   if(trendDir == 1 && c1 < zoneLo)       // bull demand zona pastdan buzildi
      broken = true;
   else if(trendDir == -1 && c1 > zoneHi) // bear supply zona yuqoridan buzildi
      broken = true;

   if(broken)
     {
      if(InpDrawZones && activeZoneName != "" && ObjectFind(0, activeZoneName) >= 0)
        {
         ObjectSetInteger(0, activeZoneName, OBJPROP_COLOR, InpBrokenColor);
         ObjectSetInteger(0, activeZoneName, OBJPROP_FILL, false);
         ChartRedraw(0);
        }
      zoneActive = false; // buzilgan zonaga endi kirmaymiz
      zoneState = "BROKEN";
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
//| Kirish strelkasini chizish                                       |
void DrawEntryArrow(bool isBuy, double price)
  {
   if(!InpShowEntryArrows) return;
   string name = ARR_PREFIX + IntegerToString(arrCounter++);
   datetime t = iTime(_Symbol, _Period, 0);
   ENUM_OBJECT ot = OBJ_ARROW_SELL;
   if(isBuy) ot = OBJ_ARROW_BUY;
   if(ObjectCreate(0, name, ot, 0, t, price))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, isBuy ? clrLime : clrRed);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }
  }
//+------------------------------------------------------------------+
//| Bildirishnoma yuborish                                           |
void Notify(string msg)
  {
   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush)  SendNotification(msg);
   Print(msg);
  }
//+------------------------------------------------------------------+
//| Panel: label yaratish/yangilash                                  |
void SetPanelLabel(string suffix, int x, int y, string text, color col, int fs)
  {
   string name = PANEL_PREFIX + suffix;
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, InpPanelCorner);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fs);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
  }
//+------------------------------------------------------------------+
//| Panel: fon to'rtburchagi                                         |
void SetPanelBG(int x, int y, int w, int h)
  {
   string name = PANEL_PREFIX + "BG";
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, InpPanelCorner);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'12,16,24');
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_COLOR, C'42,53,80');
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
  }
//+------------------------------------------------------------------+
//| Panelni yangilash                                                |
void UpdatePanel()
  {
   if(!InpShowPanel) return;

   int x0 = InpPanelX;
   int y0 = InpPanelY;
   int rh = 16;                 // qator balandligi
   int vx = x0 + 118;           // qiymat ustuni

   SetPanelBG(x0 - 6, y0 - 6, 214, rh * 18 + 14);

   // trend
   string trTxt = trendDir == 1 ? "BULL" : trendDir == -1 ? "BEAR" : "—";
   color  trCol = trendDir == 1 ? clrLime : trendDir == -1 ? clrTomato : clrSilver;

   // yuqori TF trend
   string htfTxt = !InpUseMTF ? "off"
                   : htfBias == 1 ? "BULL"
                   : htfBias == -1 ? "BEAR" : "—";
   color  htfCol = !InpUseMTF ? clrGray
                   : htfBias == 1 ? clrLime
                   : htfBias == -1 ? clrTomato : clrSilver;
   string htfTf  = StringSubstr(EnumToString(InpHTF), 7);

   // zona holati rangi
   color zCol = clrSilver;
   if(zoneState == "BULL demand") zCol = InpBullZoneColor;
   else if(zoneState == "BEAR supply") zCol = InpBearZoneColor;
   else if(zoneState == "RETEST") zCol = InpRetestColor;
   else if(zoneState == "BROKEN") zCol = InpBrokenColor;

   // pozitsiya
   string posTxt = "FLAT";
   color  posCol = clrSilver;
   string plTxt  = "—";
   color  plCol  = clrSilver;
   if(HasPosition())
     {
      long   type = PositionGetInteger(POSITION_TYPE);
      double vol  = PositionGetDouble(POSITION_VOLUME);
      double prof = PositionGetDouble(POSITION_PROFIT);
      posTxt = (type == POSITION_TYPE_BUY ? "LONG " : "SHORT ") + DoubleToString(vol, 2) + " lot";
      posCol = (type == POSITION_TYPE_BUY ? clrLime : clrTomato);
      plTxt  = DoubleToString(prof, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
      plCol  = prof >= 0 ? clrLime : clrTomato;
     }

   // spread
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   color spCol = (InpMaxSpreadPts > 0 && spread > InpMaxSpreadPts) ? clrTomato : clrSilver;

   bool algo = (bool)MQLInfoInteger(MQL_TRADE_ALLOWED) &&
               (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);

   string tf = StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7);

   // kunlik P/L va limit holati
   string cur = AccountInfoString(ACCOUNT_CURRENCY);
   double dailyPL = AccountInfoDouble(ACCOUNT_EQUITY) - dayStartEquity;
   color  dpCol = dailyPL >= 0 ? clrLime : clrTomato;
   bool   dOk = DailyOK();
   string dLimTxt = !InpUseDailyLimit ? "off" : (dOk ? "OK" : "HIT — STOP");
   color  dLimCol = !InpUseDailyLimit ? clrGray : (dOk ? clrLime : clrTomato);

   // sifat filtrlari
   double adxVal = GetADX();
   double rsiVal = GetRSI();
   string adxTxt = !InpUseADX ? "off" : DoubleToString(adxVal, 0);
   color  adxCol = !InpUseADX ? clrGray : (adxVal >= InpADXmin ? clrLime : clrTomato);
   string filtTxt = adxTxt + " / " + (!InpUseRSI ? "off" : DoubleToString(rsiVal, 0));
   string dtTxt = IntegerToString(dailyTrades) +
                  (InpMaxDailyTrades > 0 ? "/" + IntegerToString(InpMaxDailyTrades) : "");
   bool coolOn = (InpCooldownBars > 0 && TimeCurrent() < lossUntil);

   // statistika
   double winRate = statTrades > 0 ? (double)statWins / statTrades * 100.0 : 0.0;
   color  spCol2  = statProfit >= 0 ? clrLime : clrTomato;

   int r = 0;
   SetPanelLabel("T",  x0, y0 + rh*r, "◆ SMC AUTO TRADER", C'255,210,60', 10); r++;
   SetPanelLabel("k1", x0, y0 + rh*r, "Instrument", clrSilver, 8);
   SetPanelLabel("v1", vx, y0 + rh*r, _Symbol + " " + tf, clrWhite, 8); r++;
   SetPanelLabel("k2", x0, y0 + rh*r, "Trend", clrSilver, 8);
   SetPanelLabel("v2", vx, y0 + rh*r, trTxt, trCol, 8); r++;
   SetPanelLabel("k9", x0, y0 + rh*r, "HTF " + htfTf, clrSilver, 8);
   SetPanelLabel("v9", vx, y0 + rh*r, htfTxt, htfCol, 8); r++;
   SetPanelLabel("k3", x0, y0 + rh*r, "Zona", clrSilver, 8);
   SetPanelLabel("v3", vx, y0 + rh*r, zoneState, zCol, 8); r++;
   SetPanelLabel("k4", x0, y0 + rh*r, "Spread", clrSilver, 8);
   SetPanelLabel("v4", vx, y0 + rh*r, IntegerToString(spread) + " pt", spCol, 8); r++;
   SetPanelLabel("k5", x0, y0 + rh*r, "Pozitsiya", clrSilver, 8);
   SetPanelLabel("v5", vx, y0 + rh*r, posTxt, posCol, 8); r++;
   SetPanelLabel("k6", x0, y0 + rh*r, "Foyda", clrSilver, 8);
   SetPanelLabel("v6", vx, y0 + rh*r, plTxt, plCol, 8); r++;
   SetPanelLabel("k7", x0, y0 + rh*r, "Risk/savdo", clrSilver, 8);
   SetPanelLabel("v7", vx, y0 + rh*r, DoubleToString(InpRiskPercent, 1) + " %", clrWhite, 8); r++;
   SetPanelLabel("k8", x0, y0 + rh*r, "Algo Trading", clrSilver, 8);
   SetPanelLabel("v8", vx, y0 + rh*r, algo ? "ON" : "OFF", algo ? clrLime : clrTomato, 8); r++;
   SetPanelLabel("k15", x0, y0 + rh*r, "ADX / RSI", clrSilver, 8);
   SetPanelLabel("v15", vx, y0 + rh*r, filtTxt, adxCol, 8); r++;
   SetPanelLabel("k16", x0, y0 + rh*r, "Bugun savdo", clrSilver, 8);
   SetPanelLabel("v16", vx, y0 + rh*r, dtTxt + (coolOn ? "  (cooldown)" : ""),
                 coolOn ? InpRetestColor : clrWhite, 8); r++;
   SetPanelLabel("s0", x0, y0 + rh*r, "— STATISTIKA —", C'255,210,60', 8); r++;
   SetPanelLabel("k10", x0, y0 + rh*r, "Kunlik P/L", clrSilver, 8);
   SetPanelLabel("v10", vx, y0 + rh*r, DoubleToString(dailyPL, 2) + " " + cur, dpCol, 8); r++;
   SetPanelLabel("k11", x0, y0 + rh*r, "Kunlik limit", clrSilver, 8);
   SetPanelLabel("v11", vx, y0 + rh*r, dLimTxt, dLimCol, 8); r++;
   SetPanelLabel("k12", x0, y0 + rh*r, "Savdolar", clrSilver, 8);
   SetPanelLabel("v12", vx, y0 + rh*r, IntegerToString(statTrades) +
                 " (" + IntegerToString(statWins) + "W/" + IntegerToString(statLosses) + "L)", clrWhite, 8); r++;
   SetPanelLabel("k13", x0, y0 + rh*r, "G'alaba %", clrSilver, 8);
   SetPanelLabel("v13", vx, y0 + rh*r, DoubleToString(winRate, 1) + " %",
                 winRate >= 50 ? clrLime : clrSilver, 8); r++;
   SetPanelLabel("k14", x0, y0 + rh*r, "Jami P/L", clrSilver, 8);
   SetPanelLabel("v14", vx, y0 + rh*r, DoubleToString(statProfit, 2) + " " + cur, spCol2, 8); r++;
  }
//+------------------------------------------------------------------+
//| Panel obyektlarini o'chirish                                     |
void DeletePanel()
  {
   ObjectsDeleteAll(0, PANEL_PREFIX);
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
//| Yuqori TF trend biasini yangilash                                |
void UpdateHtfBias()
  {
   if(!InpUseMTF) { htfBias = 0; return; }
   double e[];
   if(CopyBuffer(hHtfEma, 0, 1, 1, e) < 1) return; // eski qiymatni saqlaymiz
   double htfClose = iClose(_Symbol, InpHTF, 1);
   if(htfClose > e[0])      htfBias = 1;
   else if(htfClose < e[0]) htfBias = -1;
   else                     htfBias = 0;
  }
//+------------------------------------------------------------------+
//| ADX asosiy chizig'i (oxirgi yopilgan bar)                        |
double GetADX()
  {
   if(!InpUseADX) return(100.0); // filtr o'chiq bo'lsa doim o'tsin
   double a[];
   if(CopyBuffer(hAdx, 0, 1, 1, a) < 1) return(0.0);
   return(a[0]);
  }
//+------------------------------------------------------------------+
//| RSI (oxirgi yopilgan bar)                                        |
double GetRSI()
  {
   if(!InpUseRSI) return(50.0); // filtr o'chiq bo'lsa neytral
   double r[];
   if(CopyBuffer(hRsi, 0, 1, 1, r) < 1) return(50.0);
   return(r[0]);
  }
//+------------------------------------------------------------------+
//| Oxirgi yopilgan savdoning natijasi (foyda/zarar)                 |
double LastClosedProfit()
  {
   if(!HistorySelect(TimeCurrent() - 30 * 86400, TimeCurrent())) return(0.0);
   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagic) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      return(HistoryDealGetDouble(ticket, DEAL_PROFIT)
           + HistoryDealGetDouble(ticket, DEAL_SWAP)
           + HistoryDealGetDouble(ticket, DEAL_COMMISSION));
     }
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Statistikani tarix bitimlaridan hisoblash                        |
void ComputeStats()
  {
   datetime from = 0;
   if(InpStatsHistoryDays > 0)
      from = TimeCurrent() - (datetime)InpStatsHistoryDays * 86400;
   if(!HistorySelect(from, TimeCurrent())) return;

   int wins = 0, losses = 0, trades = 0;
   double profit = 0.0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagic) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      double p = HistoryDealGetDouble(ticket, DEAL_PROFIT)
               + HistoryDealGetDouble(ticket, DEAL_SWAP)
               + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      profit += p;
      trades++;
      if(p >= 0) wins++; else losses++;
     }
   statTrades = trades;
   statWins   = wins;
   statLosses = losses;
   statProfit = profit;
  }
//+------------------------------------------------------------------+
//| Kunlik risk limiti: yangi savdoga ruxsat bormi                   |
bool DailyOK()
  {
   if(!InpUseDailyLimit) return(true);
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double loss = dayStartEquity - eq; // musbat = zarar
   if(dayStartEquity > 0 && loss >= dayStartEquity * InpMaxDailyLossPct / 100.0)
      return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//| Yangilik filtri: yuqori ta'sirli yangilik yaqinmi (faqat live)   |
bool NewsOK()
  {
   if(!InpUseNewsFilter) return(true);

   datetime now = TimeCurrent();
   datetime f = now - (datetime)InpNewsAfterMin * 60;
   datetime t = now + (datetime)InpNewsBeforeMin * 60;

   string base = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string prof = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);

   if(NewsHitForCurrency(base, f, t)) return(false);
   if(prof != base && NewsHitForCurrency(prof, f, t)) return(false);
   return(true); // ma'lumot bo'lmasa (tester/uzilish) savdoga ruxsat
  }
bool NewsHitForCurrency(string cur, datetime f, datetime t)
  {
   MqlCalendarValue values[];
   int n = CalendarValueHistory(values, f, t, NULL, cur);
   for(int i = 0; i < n; i++)
     {
      MqlCalendarEvent ev;
      if(!CalendarEventById(values[i].event_id, ev)) continue;
      if(ev.importance == CALENDAR_IMPORTANCE_HIGH)
         return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//| Partial close: TP1 ga yetganda hajmning bir qismini yopish       |
void ManagePartial()
  {
   if(!InpUsePartial || partialDone) return;
   if(!HasPosition()) return;

   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double tp   = PositionGetDouble(POSITION_TP);
   double vol  = PositionGetDouble(POSITION_VOLUME);
   long   type = PositionGetInteger(POSITION_TYPE);
   if(tp <= 0.0) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double tp1 = open + (tp - open) * InpPartialTPfrac; // ikki yo'nalish uchun ham to'g'ri
   bool reached = (type == POSITION_TYPE_BUY) ? (bid >= tp1) : (ask <= tp1);
   if(!reached) return;

   double minL   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double closeV = NormalizeLots(vol * InpPartialPct / 100.0);

   // hajmni toza bo'lishtira olmasak — faqat break-even qilamiz
   if(closeV >= minL && (vol - closeV) >= minL)
     {
      if(trade.PositionClosePartial(_Symbol, closeV))
        {
         Notify(StringFormat("SMC: TP1 — %.2f lot yopildi (%s)", closeV, _Symbol));
         // qolganini break-even'ga o'tkazamiz
         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         double be = (type == POSITION_TYPE_BUY) ? open + InpBElockPts * point
                                                 : open - InpBElockPts * point;
         trade.PositionModify(_Symbol, NormalizePrice(be), tp);
        }
     }
   partialDone = true; // takror urinmaslik uchun
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

   double raw  = riskMoney / lossPerLot;
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // Kichik hisob: risk hisobiga ko'ra lot minimal lotdan kichik chiqsa,
   // minimal lot belgilangan %'dan ortiq risk qiladi -> savdoni o'tkazib yuboramiz.
   if(raw < minL && InpSkipIfOverRisk)
     {
      Print("Savdo o'tkazib yuborildi: min lot risk %'dan oshib ketadi (raw=",
            DoubleToString(raw, 4), " < min=", DoubleToString(minL, 2), ")");
      return(0.0);
     }

   return(NormalizeLots(raw));
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
//| Minimal SL masofasi: ATR va broker stops-level'dan kattasi        |
double MinStopDist(double atr)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long   slvl  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double broker = (double)(slvl + 2) * point; // kichik bufer bilan
   return(MathMax(atr * InpMinStopATR, broker));
  }
//+------------------------------------------------------------------+
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
   if(!DailyOK())               return; // kunlik zarar limiti
   if(!NewsOK())                return; // yuqori ta'sirli yangilik yaqin

   // overtrading nazorati
   if(InpMaxDailyTrades > 0 && dailyTrades >= InpMaxDailyTrades) return;
   if(InpCooldownBars > 0 && TimeCurrent() < lossUntil)          return;

   // trend-kuch filtri (chopni chetlab o'tadi)
   if(InpUseADX && GetADX() < InpADXmin) return;

   double atr = GetAtr();
   if(atr <= 0.0) return;
   double buf = atr * InpZoneBufferATR;

   double rsi = GetRSI();

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
      bool htfOk   = !InpUseMTF || htfBias == 1; // yuqori TF ham bull
      bool rsiOk   = !InpUseRSI || rsi < InpRSIbuyMax; // cho'qqida sotib olmaymiz
      bool touched = (l1 <= zoneHi + buf); // narx zonaga tegdi
      bool confirm = (c1 > o1);            // bullish tasdiq
      if(trendOk && htfOk && rsiOk && touched && confirm)
        {
         double sl = zoneLo - buf;
         double minStop = MinStopDist(atr);
         if(ask - sl < minStop) sl = ask - minStop;
         double slDist = ask - sl;
         if(slDist <= 0) return;
         double tp = ask + slDist * InpRewardRR;

         double lots = CalcLots(slDist);
         if(lots <= 0) return;

         sl = NormalizePrice(sl);
         tp = NormalizePrice(tp);
         if(trade.Buy(lots, _Symbol, 0.0, sl, tp, InpComment))
           {
            zoneTraded = true;
            dailyTrades++;
            DrawEntryArrow(true, ask);
            Notify(StringFormat("SMC BUY %s @ %s | SL %s | TP %s | %.2f lot",
                   _Symbol, DoubleToString(ask,_Digits),
                   DoubleToString(sl,_Digits), DoubleToString(tp,_Digits), lots));
           }
        }
     }
   //--- BEAR: supply zonaga qaytib, bearish tasdiq shami
   else if(trendDir == -1)
     {
      bool trendOk = !InpUseTrendEMA || c1 < ema;
      bool htfOk   = !InpUseMTF || htfBias == -1; // yuqori TF ham bear
      bool rsiOk   = !InpUseRSI || rsi > InpRSIsellMin; // tubda sotmaymiz
      bool touched = (h1 >= zoneLo - buf);
      bool confirm = (c1 < o1);
      if(trendOk && htfOk && rsiOk && touched && confirm)
        {
         double sl = zoneHi + buf;
         double minStop = MinStopDist(atr);
         if(sl - bid < minStop) sl = bid + minStop;
         double slDist = sl - bid;
         if(slDist <= 0) return;
         double tp = bid - slDist * InpRewardRR;

         double lots = CalcLots(slDist);
         if(lots <= 0) return;

         sl = NormalizePrice(sl);
         tp = NormalizePrice(tp);
         if(trade.Sell(lots, _Symbol, 0.0, sl, tp, InpComment))
           {
            zoneTraded = true;
            dailyTrades++;
            DrawEntryArrow(false, bid);
            Notify(StringFormat("SMC SELL %s @ %s | SL %s | TP %s | %.2f lot",
                   _Symbol, DoubleToString(bid,_Digits),
                   DoubleToString(sl,_Digits), DoubleToString(tp,_Digits), lots));
           }
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
   // kun almashsa — kunlik risk hisobini qayta boshlaymiz
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day != curDay)
     {
      curDay = dt.day;
      dayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      dailyTrades = 0; // yangi kun — savdo hisobini nolga tushiramiz
     }

   // partial close (TP1) va pozitsiyani boshqarish
   ManagePartial();
   ManagePosition();

   // pozitsiya ochilishi/yopilishini aniqlash
   bool nowPos = HasPosition();
   if(!prevHasPos && nowPos)                 // yangi pozitsiya ochildi
      partialDone = false;
   if(prevHasPos && !nowPos)                 // pozitsiya yopildi
     {
      Notify("SMC: pozitsiya yopildi | " + _Symbol);
      ComputeStats();                        // statistikani yangilaymiz
      // zarar bilan yopilgan bo'lsa — sovish (cooldown) o'rnatamiz
      if(InpCooldownBars > 0 && LastClosedProfit() < 0.0)
         lossUntil = TimeCurrent() + (datetime)(InpCooldownBars * PeriodSeconds(_Period));
     }
   prevHasPos = nowPos;

   // panelni har tikda yangilaymiz
   UpdatePanel();

   // struktura/kirish faqat yangi bar yopilganda
   datetime bt = iTime(_Symbol, _Period, 0);
   if(bt == lastBarTime) return;
   lastBarTime = bt;

   if(Bars(_Symbol, _Period) < InpTrendEMA + InpSwing + 10) return;

   UpdateHtfBias();
   UpdateStructure();
   CheckInvalidation();
   CheckRetest();
   CheckEntry();
   if(InpDrawZones) ExtendLastZone();
  }
//+------------------------------------------------------------------+
