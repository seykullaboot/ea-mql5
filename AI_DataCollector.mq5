//+------------------------------------------------------------------+
//|                                          AI_DataCollector.mq5     |
//|                                      AI Trading Data Collector    |
//|                         สำหรับเก็บข้อมูลเพื่อ train ML model      |
//+------------------------------------------------------------------+
#property copyright "EA-MQL5 AI Trading"
#property link      ""
#property version   "1.00"
#property description "Script สำหรับเก็บข้อมูลตลาดเพื่อนำไป train AI model"
#property script_show_inputs

//--- Input Parameters
input datetime StartDate = D'2024.01.01';   // วันที่เริ่มต้น
input datetime EndDate = D'2025.10.14';     // วันที่สิ้นสุด
input string   OutputFile = "training_data.csv"; // ชื่อไฟล์ output

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("🗂️ เริ่มเก็บข้อมูลสำหรับ AI Training...");
   
   //--- สร้าง Indicators
   int handleRSI = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   int handleMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   int handleATR = iATR(_Symbol, _Period, 14);
   int handleBB = iBands(_Symbol, _Period, 20, 0, 2.0, PRICE_CLOSE);
   int handleStoch = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   
   if(handleRSI == INVALID_HANDLE || handleMACD == INVALID_HANDLE || 
      handleATR == INVALID_HANDLE || handleBB == INVALID_HANDLE || 
      handleStoch == INVALID_HANDLE)
   {
      Print("❌ ไม่สามารถสร้าง Indicators ได้!");
      return;
   }
   
   //--- เปิดไฟล์สำหรับเขียน
   int file = FileOpen(OutputFile, FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(file == INVALID_HANDLE)
   {
      Print("❌ ไม่สามารถสร้างไฟล์ได้: ", OutputFile);
      return;
   }
   
   //--- เขียน Header
   FileWrite(file, 
      "Time",
      "Open", "High", "Low", "Close", "Volume",
      "RSI",
      "MACD", "MACD_Signal", "MACD_Diff",
      "ATR",
      "BB_Upper", "BB_Middle", "BB_Lower", "BB_Position", "BB_Width",
      "Stoch_Main", "Stoch_Signal",
      "Price_Change_1", "Price_Change_4",
      "Future_Change", // Target variable
      "Future_Direction" // 1 = up, 0 = down
   );
   
   //--- คำนวณจำนวน bars
   int startBar = iBarShift(_Symbol, _Period, StartDate);
   int endBar = iBarShift(_Symbol, _Period, EndDate);
   int totalBars = startBar - endBar;
   
   Print("📊 กำลังประมวลผล ", totalBars, " bars...");
   
   //--- Buffers
   double rsi[], macd[], signal[], atr[];
   double bbUpper[], bbMiddle[], bbLower[];
   double stochMain[], stochSignal[];
   double close[], open[], high[], low[];
   long volume[];
   
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(macd, true);
   ArraySetAsSeries(signal, true);
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(bbUpper, true);
   ArraySetAsSeries(bbMiddle, true);
   ArraySetAsSeries(bbLower, true);
   ArraySetAsSeries(stochMain, true);
   ArraySetAsSeries(stochSignal, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(volume, true);
   
   int recordCount = 0;
   
   //--- Loop through bars
   for(int i = startBar; i >= endBar + 10; i--)
   {
      //--- คัดลอกข้อมูล
      if(CopyBuffer(handleRSI, 0, i, 1, rsi) < 1) continue;
      if(CopyBuffer(handleMACD, 0, i, 1, macd) < 1) continue;
      if(CopyBuffer(handleMACD, 1, i, 1, signal) < 1) continue;
      if(CopyBuffer(handleATR, 0, i, 1, atr) < 1) continue;
      if(CopyBuffer(handleBB, 0, i, 1, bbUpper) < 1) continue;
      if(CopyBuffer(handleBB, 1, i, 1, bbMiddle) < 1) continue;
      if(CopyBuffer(handleBB, 2, i, 1, bbLower) < 1) continue;
      if(CopyBuffer(handleStoch, 0, i, 1, stochMain) < 1) continue;
      if(CopyBuffer(handleStoch, 1, i, 1, stochSignal) < 1) continue;
      
      if(CopyClose(_Symbol, _Period, i, 5, close) < 5) continue;
      if(CopyOpen(_Symbol, _Period, i, 1, open) < 1) continue;
      if(CopyHigh(_Symbol, _Period, i, 1, high) < 1) continue;
      if(CopyLow(_Symbol, _Period, i, 1, low) < 1) continue;
      if(CopyTickVolume(_Symbol, _Period, i, 1, volume) < 1) continue;
      
      //--- คำนวณ Features
      double bbWidth = bbUpper[0] - bbLower[0];
      double bbPosition = (bbWidth > 0) ? (close[0] - bbLower[0]) / bbWidth : 0.5;
      double priceChange1 = close[0] - close[1];
      double priceChange4 = close[0] - close[4];
      
      //--- คำนวณ Target (ราคาในอนาคต)
      double futureClose[];
      ArraySetAsSeries(futureClose, true);
      if(CopyClose(_Symbol, _Period, i-5, 1, futureClose) < 1) continue;
      
      double futureChange = futureClose[0] - close[0];
      int futureDirection = (futureChange > 0) ? 1 : 0;
      
      //--- เขียนข้อมูลลงไฟล์
      FileWrite(file,
         TimeToString(iTime(_Symbol, _Period, i)),
         open[0], high[0], low[0], close[0], volume[0],
         rsi[0],
         macd[0], signal[0], macd[0] - signal[0],
         atr[0],
         bbUpper[0], bbMiddle[0], bbLower[0], bbPosition, bbWidth,
         stochMain[0], stochSignal[0],
         priceChange1, priceChange4,
         futureChange,
         futureDirection
      );
      
      recordCount++;
      
      //--- แสดงความคืบหน้า
      if(recordCount % 100 == 0)
      {
         double progress = (startBar - i) * 100.0 / totalBars;
         Print("⏳ ความคืบหน้า: ", DoubleToString(progress, 1), "% (", recordCount, " records)");
      }
   }
   
   //--- ปิดไฟล์
   FileClose(file);
   
   //--- Release Indicators
   IndicatorRelease(handleRSI);
   IndicatorRelease(handleMACD);
   IndicatorRelease(handleATR);
   IndicatorRelease(handleBB);
   IndicatorRelease(handleStoch);
   
   Print("✅ เก็บข้อมูลเสร็จสิ้น!");
   Print("📁 ไฟล์: ", OutputFile);
   Print("📊 จำนวนข้อมูล: ", recordCount, " records");
   Print("💡 นำไฟล์นี้ไป train ด้วย Python script");
}
//+------------------------------------------------------------------+
