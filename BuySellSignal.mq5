//+------------------------------------------------------------------+
//|                                               BuySellSignal.mq5   |
//|                          MT5 Buy/Sell Signal Indicator (EMA cross)|
//+------------------------------------------------------------------+
#property copyright "BuySellSignal"
#property version   "1.00"
#property description "Ikki EMA kesishuvi asosida Buy/Sell strelka signallarini beradi."
#property strict

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   2

//--- Buy signal (strelka pastdan yuqoriga)
#property indicator_label1  "Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_width1  2

//--- Sell signal (strelka yuqoridan pastga)
#property indicator_label2  "Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  2

//+------------------------------------------------------------------+
//| Kirish parametrlari                                              |
//+------------------------------------------------------------------+
input int                InpFastPeriod = 9;              // Tez EMA davri
input int                InpSlowPeriod = 21;             // Sekin EMA davri
input ENUM_MA_METHOD     InpMaMethod   = MODE_EMA;       // MA metodi
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE;  // Qo'llaniladigan narx
input double             InpArrowGap   = 1.0;            // Strelka masofasi (ATR ulushi)
input int                InpAtrPeriod  = 14;             // ATR davri (masofa uchun)

input bool               InpAlertPopup = true;           // Ekranda alert
input bool               InpAlertPush  = false;          // Telefonga push
input bool               InpAlertEmail = false;          // Email yuborish

//+------------------------------------------------------------------+
//| Global o'zgaruvchilar                                           |
//+------------------------------------------------------------------+
double   BuyBuffer[];
double   SellBuffer[];
double   FastBuffer[];
double   SlowBuffer[];

int      hFast = INVALID_HANDLE;
int      hSlow = INVALID_HANDLE;
int      hAtr  = INVALID_HANDLE;

datetime lastAlertTime = 0;

//+------------------------------------------------------------------+
//| Initsializatsiya                                                |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, BuyBuffer,  INDICATOR_DATA);
   SetIndexBuffer(1, SellBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, FastBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, SlowBuffer, INDICATOR_CALCULATIONS);

   //--- strelka kodlari (Wingdings)
   PlotIndexSetInteger(0, PLOT_ARROW, 233); // yuqoriga strelka (Buy)
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // pastga strelka (Sell)

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);

   //--- indikator handllari
   hFast = iMA(_Symbol, _Period, InpFastPeriod, 0, InpMaMethod, InpAppliedPrice);
   hSlow = iMA(_Symbol, _Period, InpSlowPeriod, 0, InpMaMethod, InpAppliedPrice);
   hAtr  = iATR(_Symbol, _Period, InpAtrPeriod);

   if(hFast == INVALID_HANDLE || hSlow == INVALID_HANDLE || hAtr == INVALID_HANDLE)
     {
      Print("Indikator handllarini yaratib bo'lmadi.");
      return(INIT_FAILED);
     }

   if(InpFastPeriod >= InpSlowPeriod)
      Print("Ogohlantirish: Tez EMA davri Sekin EMA davridan kichik bo'lgani ma'qul.");

   IndicatorSetString(INDICATOR_SHORTNAME,
      StringFormat("BuySellSignal(%d,%d)", InpFastPeriod, InpSlowPeriod));

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinitsializatsiya                                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(hFast != INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hAtr  != INVALID_HANDLE) IndicatorRelease(hAtr);
  }

//+------------------------------------------------------------------+
//| Hisoblash                                                       |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int needed = MathMax(InpSlowPeriod, InpAtrPeriod) + 2;
   if(rates_total < needed)
      return(0);

   //--- MA va ATR qiymatlarini ko'chirish
   int copied_fast = CopyBuffer(hFast, 0, 0, rates_total, FastBuffer);
   int copied_slow = CopyBuffer(hSlow, 0, 0, rates_total, SlowBuffer);
   if(copied_fast <= 0 || copied_slow <= 0)
      return(prev_calculated);

   double atr[];
   if(CopyBuffer(hAtr, 0, 0, rates_total, atr) <= 0)
      return(prev_calculated);

   //--- qayerdan boshlab hisoblash
   int start = prev_calculated - 1;
   if(start < needed)
      start = needed;

   for(int i = start; i < rates_total; i++)
     {
      BuyBuffer[i]  = 0.0;
      SellBuffer[i] = 0.0;

      double fastNow  = FastBuffer[i];
      double slowNow  = SlowBuffer[i];
      double fastPrev = FastBuffer[i-1];
      double slowPrev = SlowBuffer[i-1];

      double gap = atr[i] * InpArrowGap;
      if(gap <= 0) gap = (high[i] - low[i]);

      //--- Buy: tez EMA sekin EMAni pastdan yuqoriga kesib o'tdi
      if(fastPrev <= slowPrev && fastNow > slowNow)
         BuyBuffer[i] = low[i] - gap;

      //--- Sell: tez EMA sekin EMAni yuqoridan pastga kesib o'tdi
      if(fastPrev >= slowPrev && fastNow < slowNow)
         SellBuffer[i] = high[i] + gap;
     }

   //--- oxirgi yopilgan barda signal bo'lsa bildirishnoma
   if(rates_total >= 2)
     {
      int last = rates_total - 2; // yopilgan bar
      if(time[last] != lastAlertTime)
        {
         if(BuyBuffer[last] != 0.0)
           {
            SendAlerts("BUY", time[last], close[last]);
            lastAlertTime = time[last];
           }
         else if(SellBuffer[last] != 0.0)
           {
            SendAlerts("SELL", time[last], close[last]);
            lastAlertTime = time[last];
           }
        }
     }

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Bildirishnomalarni yuborish                                     |
//+------------------------------------------------------------------+
void SendAlerts(const string signal, const datetime t, const double price)
  {
   string msg = StringFormat("%s signal | %s | %s | narx: %s",
                             signal, _Symbol,
                             EnumToString((ENUM_TIMEFRAMES)_Period),
                             DoubleToString(price, _Digits));

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush)  SendNotification(msg);
   if(InpAlertEmail) SendMail("MT5 BuySellSignal", msg);
  }
//+------------------------------------------------------------------+
