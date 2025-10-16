//+------------------------------------------------------------------+
//|                                      AI_NeuralNetwork_EA.mq5     |
//|                                AI Trading with Neural Network     |
//|                                  Native MQL5 Implementation       |
//+------------------------------------------------------------------+
#property copyright "EA-MQL5 AI Trading"
#property link      ""
#property version   "2.00"
#property description "🤖 AI Expert Advisor ใช้ Neural Network แบบ Native MQL5"
#property description "รองรับ Self-Learning และ Auto-Training"

#include <Includes\NeuralNetwork.mqh>
#include <Includes\TradingFeatures.mqh>

//--- Input Parameters
input group "=== AI Settings ==="
input bool     EnableAI = true;             // เปิดใช้งาน AI
input bool     EnableLearning = true;       // เปิดใช้การเรียนรู้
input int      TrainingFrequency = 50;      // ความถี่การ train (bars)
input double   LearningRate = 0.01;         // อัตราการเรียนรู้
input double   MinConfidence = 0.60;        // ความมั่นใจขั้นต่ำ (0-1)

input group "=== Network Architecture ==="
input int      HiddenLayer1 = 50;           // Neurons ชั้นที่ 1
input int      HiddenLayer2 = 30;           // Neurons ชั้นที่ 2
input int      HiddenLayer3 = 15;           // Neurons ชั้นที่ 3

input group "=== Risk Management ==="
input double   LotSize = 0.01;              // ขนาดล็อต
input bool     UseAutoLot = true;           // คำนวณล็อตอัตโนมัติ
input double   RiskPercent = 2.0;           // ความเสี่ยงต่อเทรด (%)
input int      StopLoss = 100;              // Stop Loss (points)
input int      TakeProfit = 200;            // Take Profit (points)
input bool     UseTrailingStop = true;      // ใช้ Trailing Stop
input int      TrailingStop = 50;           // Trailing Stop (points)
input int      TrailingStep = 10;           // Trailing Step (points)

input group "=== General Settings ==="
input int      MagicNumber = 20241014;      // Magic Number
input string   TradeComment = "AI-NN";      // คอมเมนต์
input bool     SaveModel = true;            // บันทึกโมเดลอัตโนมัติ
input int      SaveInterval = 100;          // บันทึกทุกกี่ bars

//--- Global Variables
NeuralNetwork* nn;
FeatureExtractor* features;

int barCount = 0;
int trainingCount = 0;
int totalTrades = 0;
int profitableTrades = 0;

datetime lastTrainingTime = 0;
datetime lastBarTime = 0;

struct PredictionHistory
{
   datetime time;
   double prediction;
   double actual;
   bool correct;
};

PredictionHistory history[];

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("╔════════════════════════════════════════════════════════════╗");
   Print("║  🤖 AI NEURAL NETWORK TRADING SYSTEM                      ║");
   Print("║  📊 Native MQL5 Implementation                            ║");
   Print("╚════════════════════════════════════════════════════════════╝");
   
   //--- สร้าง Feature Extractor
   features = new FeatureExtractor();
   if(!features.Initialize())
   {
      Print("❌ ไม่สามารถสร้าง Feature Extractor ได้");
      return INIT_FAILED;
   }
   
   //--- สร้าง Neural Network
   Print("\n🧠 กำลังสร้าง Neural Network...");
   nn = new NeuralNetwork();
   
   int inputSize = features.GetFeatureCount();
   Print("  📥 Input Features: ", inputSize);
   
   // สร้าง architecture
   nn.AddLayer(inputSize, HiddenLayer1, "relu");
   Print("  🔹 Hidden Layer 1: ", HiddenLayer1, " neurons (ReLU)");
   
   if(HiddenLayer2 > 0)
   {
      nn.AddLayer(HiddenLayer1, HiddenLayer2, "relu");
      Print("  🔹 Hidden Layer 2: ", HiddenLayer2, " neurons (ReLU)");
   }
   
   if(HiddenLayer3 > 0 && HiddenLayer2 > 0)
   {
      nn.AddLayer(HiddenLayer2, HiddenLayer3, "relu");
      Print("  🔹 Hidden Layer 3: ", HiddenLayer3, " neurons (ReLU)");
   }
   
   // Output layer
   int lastLayer = (HiddenLayer3 > 0 && HiddenLayer2 > 0) ? HiddenLayer3 : 
                   (HiddenLayer2 > 0) ? HiddenLayer2 : HiddenLayer1;
   nn.AddLayer(lastLayer, 1, "sigmoid");
   Print("  📤 Output Layer: 1 neuron (Sigmoid)");
   
   nn.SetLearningRate(LearningRate);
   Print("  📚 Learning Rate: ", LearningRate);
   
   //--- โหลดโมเดลที่บันทึกไว้ (ถ้ามี)
   string modelFile = StringFormat("AI_NN_%s_%s.dat", _Symbol, EnumToString(_Period));
   if(FileIsExist(modelFile))
   {
      if(nn.LoadFromFile(modelFile))
         Print("  ✅ โหลดโมเดลสำเร็จ: ", modelFile);
      else
         Print("  ⚠️ ใช้โมเดลใหม่");
   }
   else
   {
      Print("  ℹ️ สร้างโมเดลใหม่");
   }
   
   //--- ตั้งค่า Chart
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   
   Print("\n✅ AI System พร้อมทำงาน!");
   Print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- บันทึกโมเดล
   if(SaveModel && nn != NULL)
   {
      string modelFile = StringFormat("AI_NN_%s_%s.dat", _Symbol, EnumToString(_Period));
      nn.SaveToFile(modelFile);
   }
   
   //--- ลบ objects
   if(nn != NULL) delete nn;
   if(features != NULL) delete features;
   
   //--- แสดงสถิติ
   double winRate = (totalTrades > 0) ? (profitableTrades * 100.0 / totalTrades) : 0;
   Print("\n╔════════════════════════════════════════════════════════════╗");
   Print("║  📊 AI TRADING STATISTICS                                 ║");
   Print("╠════════════════════════════════════════════════════════════╣");
   Print("║  Total Trades: ", totalTrades);
   Print("║  Profitable: ", profitableTrades);
   Print("║  Win Rate: ", DoubleToString(winRate, 2), "%");
   Print("║  Training Sessions: ", trainingCount);
   Print("╚════════════════════════════════════════════════════════════╝");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!EnableAI) return;
   
   //--- ตรวจสอบ bar ใหม่
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime)
   {
      // อัพเดท trailing stop
      if(UseTrailingStop)
         UpdateTrailingStops();
      return;
   }
   
   lastBarTime = currentBarTime;
   barCount++;
   
   //--- Extract features
   double featureVector[];
   if(!features.ExtractFeatures(featureVector, 1)) // ใช้ bar ที่ปิดแล้ว
   {
      Print("⚠️ ไม่สามารถ extract features ได้");
      return;
   }
   
   //--- AI Prediction
   double prediction[];
   nn.Predict(featureVector, prediction);
   double confidence = MathAbs(prediction[0] - 0.5) * 2.0; // 0-1
   
   //--- บันทึก prediction
   RecordPrediction(prediction[0]);
   
   //--- แสดงข้อมูล
   DisplayInfo(prediction[0], confidence);
   
   //--- Trading Logic
   bool buySignal = (prediction[0] > 0.5 + (1.0 - MinConfidence) / 2.0) && confidence >= MinConfidence;
   bool sellSignal = (prediction[0] < 0.5 - (1.0 - MinConfidence) / 2.0) && confidence >= MinConfidence;
   
   if(buySignal && !HasPosition(POSITION_TYPE_BUY))
   {
      CloseAllPositions(POSITION_TYPE_SELL);
      OpenTrade(ORDER_TYPE_BUY, prediction[0], confidence);
   }
   else if(sellSignal && !HasPosition(POSITION_TYPE_SELL))
   {
      CloseAllPositions(POSITION_TYPE_BUY);
      OpenTrade(ORDER_TYPE_SELL, prediction[0], confidence);
   }
   
   //--- Training
   if(EnableLearning && barCount % TrainingFrequency == 0)
   {
      TrainNetwork();
   }
   
   //--- บันทึกโมเดล
   if(SaveModel && barCount % SaveInterval == 0)
   {
      string modelFile = StringFormat("AI_NN_%s_%s.dat", _Symbol, EnumToString(_Period));
      nn.SaveToFile(modelFile);
   }
}

//+------------------------------------------------------------------+
//| Train Neural Network                                              |
//+------------------------------------------------------------------+
void TrainNetwork()
{
   Print("\n🎓 กำลัง Training Neural Network...");
   
   int trainingSamples = MathMin(100, barCount - 10);
   double totalError = 0;
   int validSamples = 0;
   
   for(int i = 10; i < 10 + trainingSamples; i++)
   {
      // Extract features สำหรับ bar นี้
      double featureVector[];
      if(!features.ExtractFeatures(featureVector, i))
         continue;
      
      // คำนวณ target (ราคาในอนาคต)
      double currentClose = iClose(_Symbol, _Period, i);
      double futureClose = iClose(_Symbol, _Period, i - 5); // ดูไปข้างหน้า 5 bars
      
      if(currentClose == 0 || futureClose == 0)
         continue;
      
      double target[];
      ArrayResize(target, 1);
      target[0] = (futureClose > currentClose) ? 1.0 : 0.0; // 1 = UP, 0 = DOWN
      
      // Train
      double error = nn.Train(featureVector, target, LearningRate);
      totalError += error;
      validSamples++;
   }
   
   if(validSamples > 0)
   {
      double avgError = totalError / validSamples;
      trainingCount++;
      lastTrainingTime = TimeCurrent();
      
      Print("✅ Training เสร็จสิ้น!");
      Print("  📊 Samples: ", validSamples);
      Print("  📉 Avg Error: ", DoubleToString(avgError, 6));
      Print("  🔄 Session: ", trainingCount);
   }
}

//+------------------------------------------------------------------+
//| Open Trade                                                        |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type, double prediction, double confidence)
{
   double price = (type == ORDER_TYPE_BUY) ? 
                  SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                  SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double sl = 0, tp = 0;
   if(type == ORDER_TYPE_BUY)
   {
      sl = (StopLoss > 0) ? price - StopLoss * _Point : 0;
      tp = (TakeProfit > 0) ? price + TakeProfit * _Point : 0;
   }
   else
   {
      sl = (StopLoss > 0) ? price + StopLoss * _Point : 0;
      tp = (TakeProfit > 0) ? price - TakeProfit * _Point : 0;
   }
   
   double lotSize = UseAutoLot ? CalculateLotSize() : LotSize;
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = type;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = StringFormat("%s|%.2f|%.2f", TradeComment, prediction, confidence);
   
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
      {
         totalTrades++;
         Print("✅ เปิด ", EnumToString(type), " | Lot: ", lotSize, 
               " | Prediction: ", DoubleToString(prediction, 3),
               " | Confidence: ", DoubleToString(confidence * 100, 1), "%");
      }
      else
      {
         Print("❌ เปิดออเดอร์ไม่สำเร็จ: ", result.retcode);
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercent / 100.0;
   
   if(StopLoss <= 0) return LotSize;
   
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double slInPrice = StopLoss * point;
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   double calculatedLot = (riskAmount * tickSize) / (slInPrice * tickValue);
   calculatedLot = MathFloor(calculatedLot / lotStep) * lotStep;
   
   return MathMax(minLot, MathMin(maxLot, calculatedLot));
}

//+------------------------------------------------------------------+
//| Check if has position                                            |
//+------------------------------------------------------------------+
bool HasPosition(ENUM_POSITION_TYPE posType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == posType)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Close All Positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(ENUM_POSITION_TYPE posType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == posType)
      {
         // ตรวจสอบกำไร/ขาดทุน
         double profit = PositionGetDouble(POSITION_PROFIT);
         if(profit > 0) profitableTrades++;
         
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
         request.deviation = 10;
         request.magic = MagicNumber;
         
         OrderSend(request, result);
      }
   }
}

//+------------------------------------------------------------------+
//| Update Trailing Stops                                            |
//+------------------------------------------------------------------+
void UpdateTrailingStops()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);
         
         double newSL = 0;
         bool needUpdate = false;
         
         if(posType == POSITION_TYPE_BUY)
         {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            newSL = bid - TrailingStop * _Point;
            
            if(bid > openPrice + TrailingStop * _Point)
            {
               if(currentSL < newSL - TrailingStep * _Point || currentSL == 0)
                  needUpdate = true;
            }
         }
         else // SELL
         {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            newSL = ask + TrailingStop * _Point;
            
            if(ask < openPrice - TrailingStop * _Point)
            {
               if(currentSL > newSL + TrailingStep * _Point || currentSL == 0)
                  needUpdate = true;
            }
         }
         
         if(needUpdate)
         {
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_SLTP;
            request.position = ticket;
            request.symbol = _Symbol;
            request.sl = newSL;
            request.tp = PositionGetDouble(POSITION_TP);
            
            OrderSend(request, result);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Record Prediction                                                 |
//+------------------------------------------------------------------+
void RecordPrediction(double prediction)
{
   int size = ArraySize(history);
   ArrayResize(history, size + 1);
   
   history[size].time = TimeCurrent();
   history[size].prediction = prediction;
   
   // Keep last 1000 records
   if(size > 1000)
      ArrayRemove(history, 0, 1);
}

//+------------------------------------------------------------------+
//| Display Info                                                      |
//+------------------------------------------------------------------+
void DisplayInfo(double prediction, double confidence)
{
   string signal = "⚪ WAIT";
   color signalColor = clrGray;
   
   if(prediction > 0.5 + (1.0 - MinConfidence) / 2.0 && confidence >= MinConfidence)
   {
      signal = "🟢 BUY";
      signalColor = clrLime;
   }
   else if(prediction < 0.5 - (1.0 - MinConfidence) / 2.0 && confidence >= MinConfidence)
   {
      signal = "🔴 SELL";
      signalColor = clrRed;
   }
   
   double winRate = (totalTrades > 0) ? (profitableTrades * 100.0 / totalTrades) : 0;
   
   Comment(StringFormat(
      "╔══════════════════════════════════════════════╗\n" +
      "║  🤖 AI NEURAL NETWORK TRADING SYSTEM        ║\n" +
      "╠══════════════════════════════════════════════╣\n" +
      "║  📊 Prediction: %.2f%% %-20s ║\n" +
      "║  💪 Confidence: %.1f%%                       ║\n" +
      "║  🎯 Signal: %-32s ║\n" +
      "╠══════════════════════════════════════════════╣\n" +
      "║  📈 Win Rate: %.1f%% (%d/%d)              ║\n" +
      "║  🎓 Training Sessions: %-18d ║\n" +
      "║  📚 Learning: %-29s ║\n" +
      "║  💾 Model Saves: %-24d ║\n" +
      "╚══════════════════════════════════════════════╝",
      prediction * 100,
      (prediction > 0.5) ? "BULLISH ↗" : "BEARISH ↘",
      confidence * 100,
      signal,
      winRate, profitableTrades, totalTrades,
      trainingCount,
      EnableLearning ? "ON ✅" : "OFF ❌",
      barCount / SaveInterval
   ));
}
//+------------------------------------------------------------------+
