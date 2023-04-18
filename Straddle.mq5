//+------------------------------------------------------------------+
//|                                                  MyEA.mq5         |
//|                        Copyright 2021, Sibusiso Shongwe          |
//|                     https://www.mycompany.com                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Sibusiso Shongwe"
#property link      "https://www.mycompany.com"
#property version   "1.00"
#property strict

//--- EA parameters
input int StopDistance = 100;
input int MagicNumber = 101;
input double LotSize = 0.04;
input int execution_hour = 14; // Set the desired PM execution time in hours (24-hour format), for example, 15 (3 PM)
input int execution_minute = 53; // Set the desired execution minute

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initialization code
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Deinitialization code
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    datetime current_time = TimeCurrent();
    MqlDateTime current_time_struct;
    TimeToStruct(current_time, current_time_struct);

    if (current_time_struct.hour != execution_hour || current_time_struct.min != execution_minute)
        return;

    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    string comment = "Sibs is trading";

    // Price must be normalized either to digits or tickSize
    askPrice = round(askPrice/tickSize) * tickSize;
    bidPrice = round(bidPrice/tickSize) * tickSize;

    // Request and Result Declaration and Initialization
    MqlTradeRequest buy_request = {};
    MqlTradeResult buy_result = {};

    MqlTradeRequest sell_request = {};
    MqlTradeResult sell_result = {};

    // Place the buy stop order
    double sell_price = bidPrice - StopDistance * _Point;

    // Place the sell stop order
    double buy_price = askPrice + StopDistance * _Point;

    buy_request.action = TRADE_ACTION_PENDING;
    buy_request.type = ORDER_TYPE_BUY_STOP;
    buy_request.symbol = _Symbol;
    buy_request.volume = LotSize;
    buy_request.price = buy_price;
    buy_request.deviation = 10;
    buy_request.magic = MagicNumber;
    buy_request.comment = comment;

    sell_request.action = TRADE_ACTION_PENDING;
    sell_request.type = ORDER_TYPE_SELL_STOP;
    sell_request.symbol = _Symbol;
    sell_request.volume = LotSize;
    sell_request.price = sell_price;
    sell_request.deviation = 10;
    sell_request.magic = MagicNumber;
    sell_request.comment = comment;

    OrderSend(buy_request, buy_result);

    OrderSend(sell_request, sell_result);
}
//+------------------------------------------------------------------+
