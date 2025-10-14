//+------------------------------------------------------------------+
//|                                            MA_Crossover_EA.mq5   |
//|                                  Expert Advisor by AI Assistant  |
//|                                        Moving Average Crossover  |
//+------------------------------------------------------------------+
#property copyright "EA-MQL5"
#property link      ""
#property version   "1.00"
#property description "Expert Advisor ที่ใช้กลยุทธ์ Moving Average Crossover"
#property description "เมื่อ MA เร็วตัด MA ช้าขึ้น = สัญญาณซื้อ (BUY)"
#property description "เมื่อ MA เร็วตัด MA ช้าลง = สัญญาณขาย (SELL)"

//--- Input Parameters
input group "=== การตั้งค่า Moving Average ==="
input int      FastMA_Period = 20;          // ช่วง MA เร็ว
input int      SlowMA_Period = 50;          // ช่วง MA ช้า
input ENUM_MA_METHOD MA_Method = MODE_EMA;  // วิธีคำนวณ MA
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // ราคาที่ใช้คำนวณ

input group "=== การจัดการความเสี่ยง ==="
input double   LotSize = 0.01;              // ขนาดล็อต
input bool     UseAutoLot = true;           // ใช้การคำนวณล็อตอัตโนมัติ
input double   RiskPercent = 2.0;           // เสี่ยงต่อการเทรด (%)
input int      StopLoss = 100;              // Stop Loss (points)
input int      TakeProfit = 200;            // Take Profit (points)

input group "=== การตั้งค่าทั่วไป ==="
input int      MagicNumber = 12345;         // Magic Number
input string   TradeComment = "MA Cross";   // คอมเมนต์การเทรด
input int      Slippage = 10;               // Slippage ที่ยอมรับได้

//--- Global Variables
int handleFastMA;
int handleSlowMA;
double fastMA[], slowMA[];
bool firstRun = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- สร้าง Indicator Handles
   handleFastMA = iMA(_Symbol, _Period, FastMA_Period, 0, MA_Method, MA_Price);
   handleSlowMA = iMA(_Symbol, _Period, SlowMA_Period, 0, MA_Method, MA_Price);
   
   if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE)
   {
      Print("ไม่สามารถสร้าง Moving Average Indicator ได้!");
      return(INIT_FAILED);
   }
   
   //--- ตั้งค่า Array เป็น Time Series
   ArraySetAsSeries(fastMA, true);
   ArraySetAsSeries(slowMA, true);
   
   Print("Expert Advisor เริ่มทำงานแล้ว - ", _Symbol, " ", EnumToString(_Period));
   Print("Fast MA: ", FastMA_Period, " | Slow MA: ", SlowMA_Period);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- ปล่อย Indicator Handles
   if(handleFastMA != INVALID_HANDLE)
      IndicatorRelease(handleFastMA);
   if(handleSlowMA != INVALID_HANDLE)
      IndicatorRelease(handleSlowMA);
      
   Print("Expert Advisor หยุดทำงาน - เหตุผล: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- ตรวจสอบว่ามี Bar ใหม่หรือไม่
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   
   if(currentBarTime == lastBarTime)
      return; // ไม่ใช่ Bar ใหม่ ออกจากฟังก์ชัน
      
   lastBarTime = currentBarTime;
   
   //--- คัดลอกข้อมูล MA
   if(CopyBuffer(handleFastMA, 0, 0, 3, fastMA) < 3 ||
      CopyBuffer(handleSlowMA, 0, 0, 3, slowMA) < 3)
   {
      Print("ไม่สามารถคัดลอกข้อมูล MA ได้!");
      return;
   }
   
   //--- ข้ามการเทรดในรอบแรก
   if(firstRun)
   {
      firstRun = false;
      return;
   }
   
   //--- ตรวจสอบสัญญาณ
   bool buySignal = CheckBuySignal();
   bool sellSignal = CheckSellSignal();
   
   //--- ดำเนินการเทรด
   if(buySignal && !HasPosition(POSITION_TYPE_BUY))
   {
      CloseAllPositions(POSITION_TYPE_SELL); // ปิด Sell positions
      OpenBuy();
   }
   else if(sellSignal && !HasPosition(POSITION_TYPE_SELL))
   {
      CloseAllPositions(POSITION_TYPE_BUY); // ปิด Buy positions
      OpenSell();
   }
}

//+------------------------------------------------------------------+
//| ตรวจสอบสัญญาณซื้อ                                                |
//+------------------------------------------------------------------+
bool CheckBuySignal()
{
   // Fast MA ตัด Slow MA ขึ้น
   bool crossUp = (fastMA[1] > slowMA[1] && fastMA[2] <= slowMA[2]);
   return crossUp;
}

//+------------------------------------------------------------------+
//| ตรวจสอบสัญญาณขาย                                                 |
//+------------------------------------------------------------------+
bool CheckSellSignal()
{
   // Fast MA ตัด Slow MA ลง
   bool crossDown = (fastMA[1] < slowMA[1] && fastMA[2] >= slowMA[2]);
   return crossDown;
}

//+------------------------------------------------------------------+
//| เปิดออเดอร์ซื้อ                                                  |
//+------------------------------------------------------------------+
void OpenBuy()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = (StopLoss > 0) ? ask - StopLoss * _Point : 0;
   double tp = (TakeProfit > 0) ? ask + TakeProfit * _Point : 0;
   double lotSize = CalculateLotSize();
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_BUY;
   request.price = ask;
   request.sl = sl;
   request.tp = tp;
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = TradeComment;
   
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
         Print("เปิด BUY สำเร็จ | ราคา: ", ask, " | Lot: ", lotSize);
      else
         Print("เปิด BUY ไม่สำเร็จ | รหัส: ", result.retcode);
   }
   else
   {
      Print("OrderSend ล้มเหลว | Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| เปิดออเดอร์ขาย                                                   |
//+------------------------------------------------------------------+
void OpenSell()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = (StopLoss > 0) ? bid + StopLoss * _Point : 0;
   double tp = (TakeProfit > 0) ? bid - TakeProfit * _Point : 0;
   double lotSize = CalculateLotSize();
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_SELL;
   request.price = bid;
   request.sl = sl;
   request.tp = tp;
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = TradeComment;
   
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
         Print("เปิด SELL สำเร็จ | ราคา: ", bid, " | Lot: ", lotSize);
      else
         Print("เปิด SELL ไม่สำเร็จ | รหัส: ", result.retcode);
   }
   else
   {
      Print("OrderSend ล้มเหลว | Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| คำนวณขนาดล็อต                                                    |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   if(!UseAutoLot)
      return LotSize;
      
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercent / 100.0;
   
   if(StopLoss <= 0)
      return LotSize;
      
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double slInPrice = StopLoss * point;
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   double calculatedLot = (riskAmount * tickSize) / (slInPrice * tickValue);
   calculatedLot = MathFloor(calculatedLot / lotStep) * lotStep;
   
   if(calculatedLot < minLot)
      calculatedLot = minLot;
   if(calculatedLot > maxLot)
      calculatedLot = maxLot;
      
   return calculatedLot;
}

//+------------------------------------------------------------------+
//| ตรวจสอบว่ามี Position หรือไม่                                    |
//+------------------------------------------------------------------+
bool HasPosition(ENUM_POSITION_TYPE posType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == posType)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| ปิดทุก Position ของประเภทที่ระบุ                                |
//+------------------------------------------------------------------+
void CloseAllPositions(ENUM_POSITION_TYPE posType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == posType)
         {
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_DEAL;
            request.position = ticket;
            request.symbol = _Symbol;
            request.volume = PositionGetDouble(POSITION_VOLUME);
            request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            request.price = (posType == POSITION_TYPE_BUY) ? 
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            request.deviation = Slippage;
            request.magic = MagicNumber;
            
            OrderSend(request, result);
         }
      }
   }
}
//+------------------------------------------------------------------+
