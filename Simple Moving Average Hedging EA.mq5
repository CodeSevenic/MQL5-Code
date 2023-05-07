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

input bool UseFillingPolicy = false;
input ENUM_ORDER_TYPE_FILLING FillingPolicy = ORDER_FILLING_FOK;

datetime glTimeBarOpen;
int MAHandle;

//+------------------------------------------------------------------+
//| Event Handlers                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   glTimeBarOpen = D'1971.01.01 00:00';

   MAHandle = MA_Init(MAPeriod, MAShift, MAMethod, MAPrice);

   if(MAHandle == -1)
     {
      Print("OnInit Fuction Stopped!");
      return(INIT_FAILED);
     }
   return (INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("Expert removed!");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//---------------------------//
//  NEW BAR CONTROL
//---------------------------//
   bool newBar = false;

// Check for new bar
   if(glTimeBarOpen != iTime(_Symbol,PERIOD_CURRENT, 0))
     {
      newBar = true;
      glTimeBarOpen = iTime(_Symbol, PERIOD_CURRENT, 0);
     };

   if(newBar == true)
     {
      //---------------------------//
      //  PRICE & INDICATORS
      //---------------------------//

      // Price
      double close1 = Close(1);
      double close2 = Close(2);


      // Normalization of close price to tick size
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      close1 = round(close1/tickSize) * tickSize;
      close2 = round(close2/tickSize) * tickSize;

      //Moving average
      double ma1 = ma(MAHandle, 1);
      double ma2 = ma(MAHandle, 2);

      //---------------------------//
      //  TRADE EXIT
      //---------------------------//

      // Exit Signal & Close Trades Execution
      string exitSignal = MA_ExitSignal(close1, close2, ma1, ma2);

      if(exitSignal == "EXIT_LONG" || exitSignal == "EXIT_SHORT")
        {
         CloseTrades(MagicNumber, exitSignal);
        }

      Sleep(1000);

      //---------------------------//
      //  TRADE PLACEMENT
      //---------------------------//

      // Entry Signal & Order Placement Execution
      string entrySignal = MA_EntrySignal(close1, close2, ma1, ma2);
      Comment("EA #", MagicNumber, " | ", exitSignal, " | ",entrySignal, " SIGNALS DETECTED");

      if((entrySignal == "LONG" || entrySignal == "SHORT") && CheckPlacedPositions(MagicNumber) == false)
        {
         ulong ticket = OpenTrades(entrySignal, MagicNumber, FixedVolume);

         //SL & TP Trade Modification
         if(ticket > 0)
           {
            double stopLoss = CalculateStopLoss(entrySignal, SLFixedPoints, SLFixedPointsMA, ma1);
            double takeProfit = CalculateTakeProfit(entrySignal, TPFixedPoints);
           }

        }
      //---------------------------//
      //  POSITION MANAGEMENT
      //---------------------------//

      //---------------------------//
      //  PRICE & INDICATORS
      //---------------------------//
     };
  }

//+-------------------------------------------------------------------+
//| EA Functions                                                     |
//+-------------------------------------------------------------------+

//+------------+// Price Functions //+-------------+//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Close(int pShift)
  {
   MqlRates bar[];                                // it creates an object of MqlRates structure
   ArraySetAsSeries(bar, true);                   // it sets our array as a series array (so current bar is position 0, previous bar is 1...)
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 3, bar); // it copies the bar price information of bars position, 1 and 2 to our array "bar"

   return bar[pShift].close; // it return the close price of the bar object
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Open(int pShift)
  {
   MqlRates bar[];                                // it creates an object of MqlRates structure
   ArraySetAsSeries(bar, true);                   // it sets our array as a series array (so current bar is position 0, previous bar is 1...)
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 3, bar); // it copies the bar price information of bars position, 1 and 2 to our array "bar"

   return bar[pShift].open; // it return the open price of the bar object
  }

//+------------+// Moving Average Functions //+-------------+//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MA_Init(int pMAPeriod, int pMAShift, ENUM_MA_METHOD pMAMethod, ENUM_APPLIED_PRICE pMAPrice)
  {
// In case of error when initializing the MA, GetLastError() will get the error code and store it in _lastError
// ResetLastError will change _lastError variable to 0
   ResetLastError();

// A unique identifier for the indicator. Used for all actions related to the indicator, such as copying data and removing the indicator
   int Handle = iMA(_Symbol, PERIOD_CURRENT,pMAPeriod,pMAShift,pMAMethod,pMAPrice);

   if(Handle == INVALID_HANDLE)
     {
      return -1;
      Print("There was an error creating the MA Indicator Handle", GetLastError());
     }

   Print("MA Indicator handle initialized successfully");

   return Handle;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ma(int pMAHandle, int pShift)
  {
   ResetLastError();

// We create and fill an array with MA values
   double ma[];
   ArraySetAsSeries(ma, true);

//We fill the array with the 3 most recent ma values
   bool fillResult = CopyBuffer(pMAHandle, 0, 0, 3, ma);
   if(fillResult == false)
     {
      Print("FILL_ERROR", GetLastError());
     }

// We ask for the ma values stored in the pShift
   double maValue = ma[pShift];

//We normalize the ma value to our symbol's digits and return it
   maValue = NormalizeDouble(maValue,_Digits);

   return maValue;
  }

//MA Entry Signal Function
string MA_EntrySignal(double pPrice1,double pPrice2, double pMA1, double pMA2)
  {
   string str = "";
   string indicatorValues;

   if(pPrice1 > pMA1 && pPrice2 <= pMA2)
     {
      str = "LONG";
     }
   else
      if(pPrice1 < pMA1 && pPrice2 >= pMA2)
        {
         str = "SHORT";
        }
      else
        {
         str = "NO_TRADE";
        }

   StringConcatenate(indicatorValues,"MA 1: ", DoubleToString(pMA1,_Digits)," | ","MA 2: ", DoubleToString(pMA2,_Digits)," | ","Close 1: ", DoubleToString(pPrice1,_Digits)," | ","Close 2: ", DoubleToString(pPrice2,_Digits));

   Print("Indicator Values: ", indicatorValues);

   return str;
  }

//MA Exit Signal Function
string MA_ExitSignal(double pPrice1,double pPrice2, double pMA1, double pMA2)
  {
   string str = "";
   string indicatorValues;
// When LONG position detected, exit SHORT position
   if(pPrice1 > pMA1 && pPrice2 <= pMA2)
     {
      str = "EXIT_SHORT";
      // When SHORT position detected, exit LONG position
     }
   else
      if(pPrice1 < pMA1 && pPrice2 >= pMA2)
        {
         str = "EXIT_LONG";
        }
      else
        {
         str = "NO_EXIT";
        }

   StringConcatenate(indicatorValues,"MA 1: ", DoubleToString(pMA1,_Digits)," | ","MA 2: ", DoubleToString(pMA2,_Digits)," | ","Close 1: ", DoubleToString(pPrice1,_Digits)," | ","Close 2: ", DoubleToString(pPrice2,_Digits));

   Print("Indicator Values: ", indicatorValues);

   return str;
  }


//+------------+// Bollinger Bands Functions //+-------------+//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int BB_Init(int pBBPeriod, int pBBShift, double pBBDeviation, ENUM_APPLIED_PRICE pBBPrice)
  {
// In case of error when initializing the Bollinger Bands, GetLastError() will get the error code and store it in _lastError
// ResetLastError will change _lastError variable to 0
   ResetLastError();

// A unique identifier for the indicator. Used for all actions related to the indicator, such as copying data and removing the indicator
   int Handle = iBands(_Symbol, PERIOD_CURRENT,pBBPeriod,pBBShift, pBBDeviation,pBBPrice);

   if(Handle == INVALID_HANDLE)
     {
      return -1;
      Print("There was an error creating the Bollinger Bands Indicator Handle", GetLastError());
     }

   Print("Bollinger Bands Indicator handle initialized successfully");

   return Handle;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BB(int pBBHandle, int pBBLineBuffer, int pShift)
  {
   ResetLastError();

// We create and fill an array with Bollinger Bands values
   double BB[];
   ArraySetAsSeries(BB, true);

//We fill the array with the 3 most recent ma values
   bool fillResult = CopyBuffer(pBBHandle, pBBLineBuffer, 0, 3, BB);
   if(fillResult == false)
     {
      Print("FILL_ERROR", GetLastError());
     }

// We ask for the ma values stored in the pShift
   double BBValue = BB[pShift];

//We normalize the ma value to our symbol's digits and return it
   BBValue = NormalizeDouble(BBValue,_Digits);

   return BBValue;
  }


//+------------+// Order Placement Functions //+-------------+//
ulong OpenTrades(string pEntrySignal, ulong pMagicNumber, double pFixedVol)
  {
// Buy positions open trades at Ask but close them at Bid
// Sell positions open trades at Bid but close them at Ask

   double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

//Price must be normalized either to digits or tickSize
   askPrice = round(askPrice/tickSize) * tickSize;
   bidPrice = round(bidPrice/tickSize) * tickSize;

   string comment = pEntrySignal + " | " + _Symbol + " | " + string(pMagicNumber);

// Request and Result Declaration and Initialization
   MqlTradeRequest request = {};
   MqlTradeResult result   = {};

   if(pEntrySignal == "LONG")
     {

      // Request Parameters
      request.action       = TRADE_ACTION_DEAL;
      request.symbol       = _Symbol;
      request.volume       = pFixedVol;
      request.type         = ORDER_TYPE_BUY;
      request.price        = askPrice;
      request.deviation    = 10;
      request.magic        = pMagicNumber;
      request.comment      = comment;

      if(UseFillingPolicy == true)
         request.type_filling = FillingPolicy;


      if(!OrderSend(request, result))
         // If request was not sent, print error code
         Print("OrderSend trade placement error: ", GetLastError());


      //Trade Information
      Print("Open ", request.symbol," ",pEntrySignal," order #",result.order,": ",result.retcode,", Volume: ",result.volume,", Price: ",DoubleToString(request.price,_Digits));

     }
   else
      if(pEntrySignal == "SHORT")
        {
         // Request Parameters
         request.action       = TRADE_ACTION_DEAL;
         request.symbol       = _Symbol;
         request.volume       = pFixedVol;
         request.type         = ORDER_TYPE_BUY;
         request.price        = bidPrice;
         request.deviation    = 10;
         request.magic        = pMagicNumber;
         request.comment      = comment;

         if(UseFillingPolicy == true)
            request.type_filling = FillingPolicy;


         if(!OrderSend(request, result))
            // If request was not sent, print error code
            Print("OrderSend trade placement error: ", GetLastError());


         //Trade Information
         Print("Open ", request.symbol," ",pEntrySignal," order #",result.order,": ",result.retcode,", Volume: ",result.volume,", Price: ",DoubleToString(request.price,_Digits));

        }

   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_DONE_PARTIAL || result.retcode == TRADE_RETCODE_NO_CHANGES)
     {
      return request.order;
     }
   else
     {
      return 0;
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeModification(ulong ticket, ulong pMagic, double pSLPrice, double pTPPrice)
  {
   double ticketSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = _Symbol;
   request.sl = round(pSLPrice/ticketSize) * ticketSize;
   request.tp = round(pTPPrice/ticketSize) * ticketSize;
   request.comment = "MOD."+ " | " + _Symbol + " | " + string(pMagic) + ", SL: " + DoubleToString(request.sl, _Digits) + ", TP: " + DoubleToString(request.tp, _Digits);
   
   if(request.sl > 0 || request.tp > 0) {
      Sleep(1000);
      bool sent = OrderSend(request, result);
      Print(result.comment);
      
      if(!sent) {
      
      }
   }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckPlacedPositions(ulong pMagic)
  {
   bool placedPositions = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong positionTicket = PositionGetTicket(i);
      PositionSelectByTicket(positionTicket);

      ulong posMagic = PositionGetInteger(POSITION_MAGIC);

      if(posMagic == pMagic)
        {
         placedPositions = true;
         break;
        }

     }

   return placedPositions;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseTrades(ulong pMagic, string pExitSignal)
  {
// Request and Result Declaration and Initialization
   MqlTradeRequest request = {};
   MqlTradeResult result   = {};

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      //Reset of request and result values
      ZeroMemory(request);
      ZeroMemory(result);

      // Select postiton by ticket
      ulong positionTicket = PositionGetTicket(i);
      PositionSelectByTicket(positionTicket);

      ulong posMagic = PositionGetInteger(POSITION_MAGIC);
      ulong posType = PositionGetInteger(POSITION_TYPE);

      if(posMagic == pMagic && pExitSignal == "EXIT_LONG" && posType == ORDER_TYPE_BUY)
        {
         request.action = TRADE_ACTION_DEAL;
         request.type = ORDER_TYPE_SELL;
         request.symbol = _Symbol;
         request.position = positionTicket;
         request.volume = PositionGetDouble(POSITION_VOLUME);
         request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         request.deviation = 10;

         bool sent = OrderSend(request, result);
         if(sent == true)
           {
            Print("Position #",positionTicket," closed");
           }
        }
      else
         if(posMagic == pMagic && pExitSignal == "EXIT_SHORT" && posType == ORDER_TYPE_SELL)
           {
            request.action = TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_BUY;
            request.symbol = _Symbol;
            request.position = positionTicket;
            request.volume = PositionGetDouble(POSITION_VOLUME);
            request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            request.deviation = 10;

            bool sent = OrderSend(request, result);
            if(sent == true)
              {
               Print("Position #",positionTicket," closed");
              }
           }
     }
  }


//+------------+// Position Management Functions //+-------------+//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateStopLoss(string pEntrySignal, int pSLFixedPoints, int pSLFixedPointsMA, double pMA)
  {
   double stopLoss = 0.0;
   double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(pEntrySignal == "LONG")
     {
      if(pSLFixedPoints > 0)
        {
         stopLoss = bidPrice - (pSLFixedPoints * _Point);
        }
      else
         if(pSLFixedPointsMA > 0)
           {
            stopLoss = pMA - (pSLFixedPointsMA * _Point);
           }
     }
   else
      if(pEntrySignal == "SHORT")
        {
         if(pSLFixedPoints > 0)
           {
            stopLoss = askPrice + (pSLFixedPoints * _Point);
           }
         else
            if(pSLFixedPointsMA > 0)
              {
               stopLoss = pMA + (pSLFixedPointsMA * _Point);
              }
        }

   stopLoss = round(stopLoss/tickSize) * tickSize;
   return stopLoss;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateTakeProfit(string pEntrySignal, int pTPFixedPoints)
  {
   double takeProfit = 0.0;
   double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(pEntrySignal == "LONG")
     {
      if(pTPFixedPoints > 0)
        {
         takeProfit = bidPrice + (pTPFixedPoints * _Point);
        }
     }
   else
      if(pEntrySignal == "SHORT")
        {
         if(pTPFixedPoints > 0)
           {
            takeProfit = askPrice - (pTPFixedPoints * _Point);
           }
        }

   takeProfit = round(takeProfit/tickSize) * tickSize;
   return takeProfit;
  }

//+------------------------------------------------------------------+
