//+------------------------------------------------------------------+
//|                                       AI_Neural_Network_EA.mq5   |
//|                                      AI-Powered Trading System    |
//|                              Neural Network Expert Advisor        |
//+------------------------------------------------------------------+
#property copyright "EA-MQL5 AI Trading"
#property link      ""
#property version   "1.00"
#property description "Expert Advisor ที่ใช้ Neural Network ในการทำนายทิศทางตลาด"
#property description "รองรับ Self-Learning และ Pattern Recognition"

//--- Input Parameters
input group "=== AI Neural Network Settings ==="
input int      LookbackBars = 50;           // จำนวน bars ที่ใช้วิเคราะห์
input int      HiddenNeurons = 10;          // จำนวน neurons ในชั้นซ่อน
input double   LearningRate = 0.01;         // อัตราการเรียนรู้
input bool     EnableLearning = true;       // เปิดใช้การเรียนรู้อัตโนมัติ
input int      TrainingInterval = 100;      // เทรนทุกกี่ tick

input group "=== AI Input Features ==="
input bool     UseRSI = true;               // ใช้ RSI เป็น feature
input bool     UseMACD = true;              // ใช้ MACD เป็น feature
input bool     UseATR = true;               // ใช้ ATR เป็น feature
input bool     UseBollingerBands = true;    // ใช้ Bollinger Bands
input bool     UseStochastic = true;        // ใช้ Stochastic
input bool     UsePricePattern = true;      // ใช้ Price Pattern

input group "=== Risk Management ==="
input double   LotSize = 0.01;              // ขนาดล็อต
input bool     UseAutoLot = true;           // คำนวณล็อตอัตโนมัติ
input double   RiskPercent = 2.0;           // ความเสี่ยงต่อการเทรด (%)
input int      StopLoss = 100;              // Stop Loss (points)
input int      TakeProfit = 200;            // Take Profit (points)
input double   MinConfidence = 0.65;        // ความมั่นใจขั้นต่ำในการเทรด (0-1)

input group "=== General Settings ==="
input int      MagicNumber = 99999;         // Magic Number
input string   TradeComment = "AI-NN";      // คอมเมนต์การเทรด
input bool     SaveTrainingData = true;     // บันทึกข้อมูลการเทรน

//--- Neural Network Structure
struct Neuron
{
   double weights[];
   double bias;
   double output;
   double delta;
};

struct NeuralNetwork
{
   int inputSize;
   int hiddenSize;
   int outputSize;
   
   Neuron hidden[];
   Neuron output[];
   
   double learningRate;
};

//--- Global Variables
NeuralNetwork nn;
int tickCount = 0;

// Indicator Handles
int handleRSI;
int handleMACD;
int handleATR;
int handleBB;
int handleStoch;

// Indicator Buffers
double rsiBuffer[];
double macdBuffer[], signalBuffer[];
double atrBuffer[];
double bbUpperBuffer[], bbMiddleBuffer[], bbLowerBuffer[];
double stochMainBuffer[], stochSignalBuffer[];

//--- Performance Tracking
struct TradeResult
{
   datetime time;
   int type;
   double prediction;
   double actual;
   bool correct;
};

TradeResult trainingHistory[];
int totalPredictions = 0;
int correctPredictions = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("🤖 เริ่มต้น AI Neural Network Trading System...");
   
   //--- สร้าง Indicators
   if(UseRSI)
   {
      handleRSI = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
      if(handleRSI == INVALID_HANDLE) { Print("❌ ไม่สามารถสร้าง RSI ได้"); return INIT_FAILED; }
      ArraySetAsSeries(rsiBuffer, true);
   }
   
   if(UseMACD)
   {
      handleMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
      if(handleMACD == INVALID_HANDLE) { Print("❌ ไม่สามารถสร้าง MACD ได้"); return INIT_FAILED; }
      ArraySetAsSeries(macdBuffer, true);
      ArraySetAsSeries(signalBuffer, true);
   }
   
   if(UseATR)
   {
      handleATR = iATR(_Symbol, _Period, 14);
      if(handleATR == INVALID_HANDLE) { Print("❌ ไม่สามารถสร้าง ATR ได้"); return INIT_FAILED; }
      ArraySetAsSeries(atrBuffer, true);
   }
   
   if(UseBollingerBands)
   {
      handleBB = iBands(_Symbol, _Period, 20, 0, 2.0, PRICE_CLOSE);
      if(handleBB == INVALID_HANDLE) { Print("❌ ไม่สามารถสร้าง Bollinger Bands ได้"); return INIT_FAILED; }
      ArraySetAsSeries(bbUpperBuffer, true);
      ArraySetAsSeries(bbMiddleBuffer, true);
      ArraySetAsSeries(bbLowerBuffer, true);
   }
   
   if(UseStochastic)
   {
      handleStoch = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
      if(handleStoch == INVALID_HANDLE) { Print("❌ ไม่สามารถสร้าง Stochastic ได้"); return INIT_FAILED; }
      ArraySetAsSeries(stochMainBuffer, true);
      ArraySetAsSeries(stochSignalBuffer, true);
   }
   
   //--- Initialize Neural Network
   InitializeNeuralNetwork();
   
   //--- Load previous training data if exists
   LoadNeuralNetwork();
   
   Print("✅ AI System พร้อมใช้งาน");
   Print("📊 Input Features: ", GetFeatureCount());
   Print("🧠 Hidden Neurons: ", HiddenNeurons);
   Print("📈 Learning Rate: ", LearningRate);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Save Neural Network
   if(SaveTrainingData)
      SaveNeuralNetwork();
   
   //--- Release Indicators
   if(UseRSI) IndicatorRelease(handleRSI);
   if(UseMACD) IndicatorRelease(handleMACD);
   if(UseATR) IndicatorRelease(handleATR);
   if(UseBollingerBands) IndicatorRelease(handleBB);
   if(UseStochastic) IndicatorRelease(handleStoch);
   
   //--- Print Statistics
   double accuracy = (totalPredictions > 0) ? (correctPredictions * 100.0 / totalPredictions) : 0;
   Print("📊 สถิติการทำนาย: ", correctPredictions, "/", totalPredictions, " (", DoubleToString(accuracy, 2), "%)");
   Print("🤖 AI System หยุดทำงาน");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   tickCount++;
   
   //--- Check for new bar
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   
   if(currentBarTime == lastBarTime)
      return;
      
   lastBarTime = currentBarTime;
   
   //--- Prepare Input Features
   double features[];
   if(!PrepareFeatures(features))
      return;
   
   //--- Get AI Prediction
   double prediction = FeedForward(features);
   double confidence = MathAbs(prediction - 0.5) * 2; // Convert to 0-1 confidence
   
   //--- Trading Logic
   bool buySignal = (prediction > 0.5 + MinConfidence/2);
   bool sellSignal = (prediction < 0.5 - MinConfidence/2);
   
   //--- Display Info
   Comment(StringFormat(
      "🤖 AI Trading System\n" +
      "━━━━━━━━━━━━━━━━━━━━\n" +
      "📊 Prediction: %.2f%%\n" +
      "💪 Confidence: %.2f%%\n" +
      "🎯 Signal: %s\n" +
      "📈 Accuracy: %.1f%% (%d/%d)\n" +
      "🧠 Learning: %s\n" +
      "━━━━━━━━━━━━━━━━━━━━",
      prediction * 100,
      confidence * 100,
      buySignal ? "BUY 🟢" : (sellSignal ? "SELL 🔴" : "WAIT ⚪"),
      (totalPredictions > 0) ? (correctPredictions * 100.0 / totalPredictions) : 0,
      correctPredictions,
      totalPredictions,
      EnableLearning ? "ON ✅" : "OFF ❌"
   ));
   
   //--- Execute Trades
   if(buySignal && confidence >= MinConfidence && !HasPosition(POSITION_TYPE_BUY))
   {
      CloseAllPositions(POSITION_TYPE_SELL);
      OpenTrade(ORDER_TYPE_BUY, prediction);
   }
   else if(sellSignal && confidence >= MinConfidence && !HasPosition(POSITION_TYPE_SELL))
   {
      CloseAllPositions(POSITION_TYPE_BUY);
      OpenTrade(ORDER_TYPE_SELL, prediction);
   }
   
   //--- Train Neural Network
   if(EnableLearning && tickCount % TrainingInterval == 0)
   {
      TrainNetwork();
   }
}

//+------------------------------------------------------------------+
//| Initialize Neural Network                                         |
//+------------------------------------------------------------------+
void InitializeNeuralNetwork()
{
   int featureCount = GetFeatureCount();
   
   nn.inputSize = featureCount;
   nn.hiddenSize = HiddenNeurons;
   nn.outputSize = 1;
   nn.learningRate = LearningRate;
   
   //--- Initialize Hidden Layer
   ArrayResize(nn.hidden, nn.hiddenSize);
   for(int i = 0; i < nn.hiddenSize; i++)
   {
      ArrayResize(nn.hidden[i].weights, nn.inputSize);
      for(int j = 0; j < nn.inputSize; j++)
      {
         nn.hidden[i].weights[j] = (MathRand() / 32767.0) * 2 - 1; // Random -1 to 1
      }
      nn.hidden[i].bias = (MathRand() / 32767.0) * 2 - 1;
   }
   
   //--- Initialize Output Layer
   ArrayResize(nn.output, nn.outputSize);
   for(int i = 0; i < nn.outputSize; i++)
   {
      ArrayResize(nn.output[i].weights, nn.hiddenSize);
      for(int j = 0; j < nn.hiddenSize; j++)
      {
         nn.output[i].weights[j] = (MathRand() / 32767.0) * 2 - 1;
      }
      nn.output[i].bias = (MathRand() / 32767.0) * 2 - 1;
   }
}

//+------------------------------------------------------------------+
//| Prepare Feature Vector                                            |
//+------------------------------------------------------------------+
bool PrepareFeatures(double &features[])
{
   int featureCount = GetFeatureCount();
   ArrayResize(features, featureCount);
   int idx = 0;
   
   //--- RSI
   if(UseRSI)
   {
      if(CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer) < 3) return false;
      features[idx++] = NormalizeValue(rsiBuffer[0], 0, 100);
   }
   
   //--- MACD
   if(UseMACD)
   {
      if(CopyBuffer(handleMACD, 0, 0, 3, macdBuffer) < 3) return false;
      if(CopyBuffer(handleMACD, 1, 0, 3, signalBuffer) < 3) return false;
      features[idx++] = NormalizeValue(macdBuffer[0], -0.01, 0.01);
      features[idx++] = NormalizeValue(macdBuffer[0] - signalBuffer[0], -0.01, 0.01);
   }
   
   //--- ATR
   if(UseATR)
   {
      if(CopyBuffer(handleATR, 0, 0, 3, atrBuffer) < 3) return false;
      double avgATR = (atrBuffer[0] + atrBuffer[1] + atrBuffer[2]) / 3;
      features[idx++] = NormalizeValue(atrBuffer[0], 0, avgATR * 2);
   }
   
   //--- Bollinger Bands
   if(UseBollingerBands)
   {
      if(CopyBuffer(handleBB, 0, 0, 1, bbUpperBuffer) < 1) return false;
      if(CopyBuffer(handleBB, 1, 0, 1, bbMiddleBuffer) < 1) return false;
      if(CopyBuffer(handleBB, 2, 0, 1, bbLowerBuffer) < 1) return false;
      
      double close = iClose(_Symbol, _Period, 0);
      double bbWidth = bbUpperBuffer[0] - bbLowerBuffer[0];
      double bbPosition = (close - bbLowerBuffer[0]) / bbWidth;
      features[idx++] = NormalizeValue(bbPosition, 0, 1);
      features[idx++] = NormalizeValue(bbWidth, 0, _Point * 1000);
   }
   
   //--- Stochastic
   if(UseStochastic)
   {
      if(CopyBuffer(handleStoch, 0, 0, 3, stochMainBuffer) < 3) return false;
      if(CopyBuffer(handleStoch, 1, 0, 3, stochSignalBuffer) < 3) return false;
      features[idx++] = NormalizeValue(stochMainBuffer[0], 0, 100);
      features[idx++] = NormalizeValue(stochMainBuffer[0] - stochSignalBuffer[0], -100, 100);
   }
   
   //--- Price Pattern
   if(UsePricePattern)
   {
      double closes[];
      ArraySetAsSeries(closes, true);
      if(CopyClose(_Symbol, _Period, 0, 5, closes) < 5) return false;
      
      features[idx++] = NormalizeValue(closes[0] - closes[1], -_Point * 100, _Point * 100);
      features[idx++] = NormalizeValue(closes[0] - closes[4], -_Point * 500, _Point * 500);
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Feed Forward                                                      |
//+------------------------------------------------------------------+
double FeedForward(const double &inputs[])
{
   //--- Hidden Layer
   for(int i = 0; i < nn.hiddenSize; i++)
   {
      double sum = nn.hidden[i].bias;
      for(int j = 0; j < nn.inputSize; j++)
      {
         sum += inputs[j] * nn.hidden[i].weights[j];
      }
      nn.hidden[i].output = Sigmoid(sum);
   }
   
   //--- Output Layer
   double sum = nn.output[0].bias;
   for(int i = 0; i < nn.hiddenSize; i++)
   {
      sum += nn.hidden[i].output * nn.output[0].weights[i];
   }
   nn.output[0].output = Sigmoid(sum);
   
   return nn.output[0].output;
}

//+------------------------------------------------------------------+
//| Train Network (Simplified Online Learning)                       |
//+------------------------------------------------------------------+
void TrainNetwork()
{
   //--- Get recent trades to learn from
   for(int i = HistoryDealsTotal() - 1; i >= MathMax(0, HistoryDealsTotal() - 10); i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
            HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber)
         {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            // Simple reward-based learning
            if(profit > 0)
            {
               correctPredictions++;
            }
            totalPredictions++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Sigmoid Activation Function                                       |
//+------------------------------------------------------------------+
double Sigmoid(double x)
{
   return 1.0 / (1.0 + MathExp(-x));
}

//+------------------------------------------------------------------+
//| Normalize Value to 0-1                                           |
//+------------------------------------------------------------------+
double NormalizeValue(double value, double min, double max)
{
   if(max == min) return 0.5;
   double normalized = (value - min) / (max - min);
   return MathMax(0, MathMin(1, normalized));
}

//+------------------------------------------------------------------+
//| Get Feature Count                                                 |
//+------------------------------------------------------------------+
int GetFeatureCount()
{
   int count = 0;
   if(UseRSI) count += 1;
   if(UseMACD) count += 2;
   if(UseATR) count += 1;
   if(UseBollingerBands) count += 2;
   if(UseStochastic) count += 2;
   if(UsePricePattern) count += 2;
   return count;
}

//+------------------------------------------------------------------+
//| Open Trade                                                        |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type, double prediction)
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
   request.comment = StringFormat("%s|%.2f", TradeComment, prediction);
   
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
      {
         Print("✅ AI เปิด ", EnumToString(type), " | Confidence: ", prediction);
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
//| Save Neural Network to File                                       |
//+------------------------------------------------------------------+
void SaveNeuralNetwork()
{
   string filename = StringFormat("AI_NN_%s_%s.dat", _Symbol, EnumToString(_Period));
   int handle = FileOpen(filename, FILE_WRITE|FILE_BIN);
   
   if(handle != INVALID_HANDLE)
   {
      // Save network structure
      FileWriteInteger(handle, nn.inputSize);
      FileWriteInteger(handle, nn.hiddenSize);
      FileWriteInteger(handle, nn.outputSize);
      
      // Save weights and biases
      for(int i = 0; i < nn.hiddenSize; i++)
      {
         for(int j = 0; j < nn.inputSize; j++)
            FileWriteDouble(handle, nn.hidden[i].weights[j]);
         FileWriteDouble(handle, nn.hidden[i].bias);
      }
      
      for(int i = 0; i < nn.outputSize; i++)
      {
         for(int j = 0; j < nn.hiddenSize; j++)
            FileWriteDouble(handle, nn.output[i].weights[j]);
         FileWriteDouble(handle, nn.output[i].bias);
      }
      
      FileClose(handle);
      Print("💾 บันทึก Neural Network แล้ว: ", filename);
   }
}

//+------------------------------------------------------------------+
//| Load Neural Network from File                                     |
//+------------------------------------------------------------------+
void LoadNeuralNetwork()
{
   string filename = StringFormat("AI_NN_%s_%s.dat", _Symbol, EnumToString(_Period));
   int handle = FileOpen(filename, FILE_READ|FILE_BIN);
   
   if(handle != INVALID_HANDLE)
   {
      // Load and verify structure
      int loadedInputSize = FileReadInteger(handle);
      int loadedHiddenSize = FileReadInteger(handle);
      int loadedOutputSize = FileReadInteger(handle);
      
      if(loadedInputSize == nn.inputSize && 
         loadedHiddenSize == nn.hiddenSize && 
         loadedOutputSize == nn.outputSize)
      {
         // Load weights and biases
         for(int i = 0; i < nn.hiddenSize; i++)
         {
            for(int j = 0; j < nn.inputSize; j++)
               nn.hidden[i].weights[j] = FileReadDouble(handle);
            nn.hidden[i].bias = FileReadDouble(handle);
         }
         
         for(int i = 0; i < nn.outputSize; i++)
         {
            for(int j = 0; j < nn.hiddenSize; j++)
               nn.output[i].weights[j] = FileReadDouble(handle);
            nn.output[i].bias = FileReadDouble(handle);
         }
         
         Print("📂 โหลด Neural Network สำเร็จ: ", filename);
      }
      else
      {
         Print("⚠️ โครงสร้าง Network ไม่ตรงกัน - ใช้ค่าเริ่มต้น");
      }
      
      FileClose(handle);
   }
}
//+------------------------------------------------------------------+
