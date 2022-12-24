//+------------------------------------------------------------------+
//|                             Simple Moving Average Hedging EA.mq5 |
//|                                                    Code{}Sevenic |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| EA Enumarations                                                  |
//+------------------------------------------------------------------+
#property copyright "Code{}Sevenic"
#property description "Moving Average Expert Advisor"
#property link "https://www.mql5.com"
#property version "1.00"
//+------------------------------------------------------------------+
//| EA Enumarations                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Input & Global Variables                                         |
//+------------------------------------------------------------------+
sinput group                                     "EA GENERAL SETTINGS"        
input ulong MagicNumber =                        101;

sinput group "MOVING AVERAGE SETTINGS"
input int MAPeriod = 30;
input ENUM_MA_METHOD 
MAMethod = MODE_SMA;
input int MAShift = 0;
input ENUM_APPLIED_PRICE 
MAPrice = PRICE_CLOSE;

sinput group "MONEY MANAGEMENT"
input double FixedVolume = 0.01;

sinput group "POSITION MANAGEMENT"
input ushort SLFixedPoints = 0;
input ushort SLFixedPointsMA = 200;
input ushort TPFixedPoints = 0;
input ushort TSLFixedPoints = 0;
input ushort BEFixedPoints = 0;

datetime glTimeBarOpen;
int MAHandle;

//+------------------------------------------------------------------+
//| Event Handlers                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   glTimeBarOpen = D'1971.01.01 00:00';

   MAHandle = MA_Init(MAPeriod, MAShift, MAMethod, MAPrice);

   if(MAHandle) {
      return(INIT_FAILED);
   }
   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Print("Expert removed");
}

void OnTick()
{
   //---------------------------//
   //  NEW BAR CONTROL
   //---------------------------//
   bool newBar = false;

   // Check for new bar
   if (glTimeBarOpen != iTime(_Symbol,PERIOD_CURRENT, 0))
   {
      newBar = true;
      glTimeBarOpen = iTime(_Symbol, PERIOD_CURRENT, 0);
   };

   if (newBar == true)
   {
      //---------------------------//
      //  PRICE & INDICATORS
      //---------------------------//

      // Price
      double close = Close(1);
      double open = Open(1);

      Print("The Open Price is: ", open);

      // Normalization of close price to digits
      close = NormalizeDouble(close, _Digits);

      // Normalization of close price to tick size
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double closeTickSize = round(close / tickSize) * tickSize;

      //---------------------------//
      //  TRADE EXIT
      //---------------------------//

      //---------------------------//
      //  PRICE & INDICATORS
      //---------------------------//

      //---------------------------//
      //  PRICE & INDICATORS
      //---------------------------//
   };
}

//+-------------------------------------------------------------------+
//| EA Functions                                                     |
//+------------------------------------------------------------------+

//+------------+// Price Functions //+-------------+//

double Close(int pShift)
{
   MqlRates bar[];                                // it creates an object of MqlRates structure
   ArraySetAsSeries(bar, true);                   // it sets our array as a series array (so current bar is position 0, previous bar is 1...)
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 3, bar); // it copies the bar price information of bars position, 1 and 2 to our array "bar"

   return bar[pShift].close; // it return the close price of the bar object
}

double Open(int pShift)
{
   MqlRates bar[];                                // it creates an object of MqlRates structure
   ArraySetAsSeries(bar, true);                   // it sets our array as a series array (so current bar is position 0, previous bar is 1...)
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 3, bar); // it copies the bar price information of bars position, 1 and 2 to our array "bar"

   return bar[pShift].open; // it return the open price of the bar object
}

//+------------+// Moving Average Functions //+-------------+//

int MA_Init(int pMAPeriod, int pMAShift, ENUM_MA_METHOD pMAMethod, ENUM_APPLIED_PRICE pMAPrice){
   // In case of error when initializing the MA, GetLastError() will get the error code and store it in _lastError
   // ResetLastError will change _lastError variable to 0
   ResetLastError();

   // A unique identifier for the indicator. Used for all actions related to the indicator, such as copying data and removing the indicator
   int Handle = iMA(_Symbol, PERIOD_CURRENT,pMAPeriod,pMAShift,pMAMethod, pMAPrice);

   if (Handle == INVALID_HANDLE) {
      return -1;
      Print("There was an error creating the MA Indicator Handle", GetLastError());
   }

   Print("MA Indicator handle initialized successfully");

   return Handle;
}

double ma(int pMAHandle, int pShift) {
   ResetLastError();

   // We create and fill an array with MA values
   double ma[];
   ArraySetAsSeries(ma, true);

   //We fill the array with the 3 most recent ma values
   bool fillResult = CopyBuffer(pMAHandle, 0,0 , ma);
   if(fillResult == false) {
      Print("FILL_ERROR", GetLastError());
   }
}