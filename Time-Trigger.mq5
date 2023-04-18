#property copyright "Copyright 2021, My Company"
#property link      "https://www.mycompany.com"
#property version   "1.00"
#property strict

input datetime TimeToTrigger = D'2023.04.06 14:29';
input int StopDistance = 10;
int StopLoss = 10;
int TakeProfit = 30;
int MagicNumber = 101;

// expert initialization function
void OnInit()
{
    // Set the trigger time
    EventSetMillisecondTimer(TimeToTrigger);
}

// timer event function
void OnTimer()
{
    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    
    string comment = "Sibs is trading";
      
    //Price must be normalized either to digits or tickSize
    askPrice = round(askPrice/tickSize) * tickSize;
    bidPrice = round(bidPrice/tickSize) * tickSize;
    
     // Request and Result Declaration and Initialization
     MqlTradeRequest buy_request = {};
     MqlTradeResult buy_result = {};
     
     MqlTradeRequest sell_request = {};
     MqlTradeResult sell_result = {};
     
     // Place the buy stop order
     double buy_price = bidPrice - StopDistance * _Point;
     
      buy_request.action = TRADE_ACTION_PENDING;
      buy_request.type = ORDER_TYPE_BUY_STOP;
      buy_request.symbol = _Symbol;
      buy_request.volume = 0.01;
      buy_request.type = ORDER_TYPE_BUY;
      buy_request.price = buy_price;
      buy_request.deviation = 10;
      buy_request.magic = MagicNumber;
      buy_request.comment = comment;

     // Place the sell stop order
     double sell_price = askPrice + StopDistance * _Point;
    
      sell_request.action = TRADE_ACTION_PENDING;
      sell_request.type = ORDER_TYPE_SELL_STOP;
      sell_request.symbol = _Symbol;
      sell_request.volume = 0.01;
      sell_request.type = ORDER_TYPE_BUY;
      sell_request.price = sell_price;
      sell_request.deviation = 10;
      sell_request.magic = MagicNumber;
      sell_request.comment = comment;
    
    
   

    //int buy_ticket = OrderSend(_Symbol, OP_BUYSTOP, 1, buy_price, 3, buy_price - (StopLoss * _Point), buy_price + (TakeProfit * _Point));
    OrderSend(buy_request, buy_result);
      

    //int sell_ticket = OrderSend(_Symbol, OP_SELLSTOP, 1, sell_price, 3, sell_price + (StopLoss * _Point), sell_price - (TakeProfit * _Point));
    OrderSend(sell_request, sell_result);
}
