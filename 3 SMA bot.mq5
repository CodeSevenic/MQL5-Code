//+------------------------------------------------------------------+
//|                                            ThreeSMAEA.mq5         |
//|                                Copyright © 2023, Your Name        |
//|                                             https://yourwebsite   |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2023, Your Name"
#property link      "https://yourwebsite"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

input int FastSMA_Period = 5;
input int MediumSMA_Period = 13;
input int SlowSMA_Period = 34;
input int SMA_Shift = 0;

input color FastSMA_Color = clrRed;
input color MediumSMA_Color = clrBlue;
input color SlowSMA_Color = clrGreen;

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
// Create SMA lines on the chart
   ObjectCreate(0, "FastSMA", OBJ_TREND, 0, iTime(_Symbol, _Period, 0), 0, iTime(_Symbol, _Period, 1), 0);
   ObjectSetInteger(0, "FastSMA", OBJPROP_COLOR, FastSMA_Color);
   ObjectSetInteger(0, "FastSMA", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "FastSMA", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "FastSMA", OBJPROP_RAY_RIGHT, false);

   ObjectCreate(0, "MediumSMA", OBJ_TREND, 0, iTime(_Symbol, _Period, 0), 0, iTime(_Symbol, _Period, 1), 0);
   ObjectSetInteger(0, "MediumSMA", OBJPROP_COLOR, MediumSMA_Color);
   ObjectSetInteger(0, "MediumSMA", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "MediumSMA", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "MediumSMA", OBJPROP_RAY_RIGHT, false);

   ObjectCreate(0, "SlowSMA", OBJ_TREND, 0, iTime(_Symbol, _Period, 0), 0, iTime(_Symbol, _Period, 1), 0);
   ObjectSetInteger(0, "SlowSMA", OBJPROP_COLOR, SlowSMA_Color);
   ObjectSetInteger(0, "SlowSMA", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "SlowSMA", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SlowSMA", OBJPROP_RAY_RIGHT, false);

// Remove all indicators except the EA MAs
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
     {
      string obj_name = ObjectName(0, i);
      if(obj_name != "FastSMA" && obj_name != "MediumSMA" && obj_name != "SlowSMA")
        {
         ObjectDelete(0, obj_name);
        }
     }



   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(reason != REASON_CHARTCHANGE)
     {
      // Delete SMA lines from the chart
      ObjectDelete(0, "FastSMA");
      ObjectDelete(0, "MediumSMA");
      ObjectDelete(0, "SlowSMA");
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   UpdateSMALines();

   double FastSMA_Current = iMA(_Symbol, _Period, FastSMA_Period, SMA_Shift, MODE_SMA, PRICE_CLOSE);
   double FastSMA_Previous = iMA(_Symbol, _Period, FastSMA_Period, SMA_Shift + 1, MODE_SMA, PRICE_CLOSE);

   double MediumSMA_Current = iMA(_Symbol, _Period, MediumSMA_Period, SMA_Shift, MODE_SMA, PRICE_CLOSE);
   double MediumSMA_Previous = iMA(_Symbol, _Period, MediumSMA_Period, SMA_Shift + 1, MODE_SMA, PRICE_CLOSE);
   double SlowSMA_Current = iMA(_Symbol, _Period, SlowSMA_Period, SMA_Shift, MODE_SMA, PRICE_CLOSE);

// Update SMA lines on the chart
   ObjectMove(0, "FastSMA", 0, iTime(_Symbol, _Period, 0), FastSMA_Current);
   ObjectMove(0, "FastSMA", 1, iTime(_Symbol, _Period, 1), FastSMA_Previous);

   ObjectMove(0, "MediumSMA", 0, iTime(_Symbol, _Period, 0), MediumSMA_Current);
   ObjectMove(0, "MediumSMA", 1, iTime(_Symbol, _Period, 1), MediumSMA_Previous);

   ObjectMove(0, "SlowSMA", 0, iTime(_Symbol, _Period, 0), SlowSMA_Current);
   ObjectMove(0, "SlowSMA", 1, iTime(_Symbol, _Period, 1), iMA(_Symbol, _Period, SlowSMA_Period, SMA_Shift + 1, MODE_SMA, PRICE_CLOSE));


   if(FastSMA_Current > MediumSMA_Current && MediumSMA_Current > SlowSMA_Current && FastSMA_Previous <= MediumSMA_Previous)
     {
      if(PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         trade.PositionClose(_Symbol);
      trade.Buy(0.01, _Symbol);
     }

   if(FastSMA_Current < MediumSMA_Current && MediumSMA_Current < SlowSMA_Current && FastSMA_Previous >= MediumSMA_Previous)
     {
      if(PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         trade.PositionClose(_Symbol);
      trade.Sell(0.01, _Symbol);
     }
  }
//+------------------------------------------------------------------+
void UpdateSMALines()
  {
   double FastSMA_Current = iMA(_Symbol, _Period, FastSMA_Period, SMA_Shift, MODE_SMA, PRICE_CLOSE);
   double FastSMA_Previous = iMA(_Symbol, _Period, FastSMA_Period, SMA_Shift + 1, MODE_SMA, PRICE_CLOSE);

   double MediumSMA_Current = iMA(_Symbol, _Period, MediumSMA_Period, SMA_Shift, MODE_SMA, PRICE_CLOSE);
   double MediumSMA_Previous = iMA(_Symbol, _Period, MediumSMA_Period, SMA_Shift + 1, MODE_SMA, PRICE_CLOSE);

   double SlowSMA_Current = iMA(_Symbol, _Period, SlowSMA_Period, SMA_Shift, MODE_SMA, PRICE_CLOSE);

// Update SMA lines on the chart
   ObjectMove(0, "FastSMA", 0, iTime(_Symbol, _Period, 0), FastSMA_Current);
   ObjectMove(0, "FastSMA", 1, iTime(_Symbol, _Period, 1), FastSMA_Previous);

   ObjectMove(0, "MediumSMA", 0, iTime(_Symbol, _Period, 0), MediumSMA_Current);
   ObjectMove(0, "MediumSMA", 1, iTime(_Symbol, _Period, 1), MediumSMA_Previous);

   ObjectMove(0, "SlowSMA", 0, iTime(_Symbol, _Period, 0), SlowSMA_Current);
   ObjectMove(0, "SlowSMA", 1, iTime(_Symbol, _Period, 1), iMA(_Symbol, _Period, SlowSMA_Period, SMA_Shift + 1, MODE_SMA, PRICE_CLOSE));
  }
//+------------------------------------------------------------------+
