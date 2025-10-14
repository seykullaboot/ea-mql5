//+------------------------------------------------------------------+
//|                                       AI_DataCollector.mq5       |
//|                                   AI Trading Data Collection      |
//|                      เก็บข้อมูลสำหรับ train ML models            |
//+------------------------------------------------------------------+
#property copyright "EA-MQL5 AI Trading"
#property link      ""
#property version   "2.00"
#property description "📊 Script สำหรับเก็บข้อมูลตลาดเพื่อ train AI models"
#property script_show_inputs

#include <Includes\TradingFeatures.mqh>

//--- Input Parameters
input datetime StartDate = D'2023.01.01';   // วันที่เริ่มต้น
input datetime EndDate = D'2024.12.31';     // วันที่สิ้นสุด
input int      FutureBars = 5;              // จำนวน bars ในอนาคตสำหรับ target
input string   OutputFile = "ai_training_data.csv"; // ชื่อไฟล์ output
input bool     IncludeHeaders = true;       // รวม headers ในไฟล์

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("╔════════════════════════════════════════════════════════════╗");
   Print("║  📊 AI DATA COLLECTOR                                     ║");
   Print("║  Collecting market data for ML training                  ║");
   Print("╚════════════════════════════════════════════════════════════╝");
   
   //--- สร้าง Feature Extractor
   FeatureExtractor* features = new FeatureExtractor();
   if(!features.Initialize())
   {
      Print("❌ ไม่สามารถสร้าง Feature Extractor ได้");
      delete features;
      return;
   }
   
   //--- เปิดไฟล์
   int file = FileOpen(OutputFile, FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(file == INVALID_HANDLE)
   {
      Print("❌ ไม่สามารถสร้างไฟล์: ", OutputFile);
      delete features;
      return;
   }
   
   //--- เขียน Headers
   if(IncludeHeaders)
   {
      WriteHeaders(file, features);
   }
   
   //--- คำนวณจำนวน bars
   int startBar = iBarShift(_Symbol, _Period, StartDate);
   int endBar = iBarShift(_Symbol, _Period, EndDate);
   
   if(startBar < 0) startBar = iBars(_Symbol, _Period) - 1;
   if(endBar < 0) endBar = 0;
   
   int totalBars = startBar - endBar;
   
   Print("\n📊 ข้อมูลการเก็บ:");
   Print("  Symbol: ", _Symbol);
   Print("  Timeframe: ", EnumToString(_Period));
   Print("  Start: ", TimeToString(StartDate));
   Print("  End: ", TimeToString(EndDate));
   Print("  Total Bars: ", totalBars);
   Print("  Future Bars: ", FutureBars);
   Print("");
   
   int recordCount = 0;
   int errorCount = 0;
   datetime startTime = TimeCurrent();
   
   //--- วนลูปเก็บข้อมูล
   for(int i = startBar; i >= endBar + FutureBars + 10; i--)
   {
      // Extract features
      double featureVector[];
      if(!features.ExtractFeatures(featureVector, i))
      {
         errorCount++;
         continue;
      }
      
      // ดึงข้อมูล price
      datetime time = iTime(_Symbol, _Period, i);
      double open = iOpen(_Symbol, _Period, i);
      double high = iHigh(_Symbol, _Period, i);
      double low = iLow(_Symbol, _Period, i);
      double close = iClose(_Symbol, _Period, i);
      long volume = iVolume(_Symbol, _Period, i);
      
      // คำนวณ target
      double futureClose = iClose(_Symbol, _Period, i - FutureBars);
      double futureChange = futureClose - close;
      double futureChangePercent = (close > 0) ? (futureChange / close * 100.0) : 0;
      int futureDirection = (futureChange > 0) ? 1 : 0;
      
      // Calculate future high/low for more detailed targets
      double futureHigh = high;
      double futureLow = low;
      for(int j = 1; j <= FutureBars; j++)
      {
         double h = iHigh(_Symbol, _Period, i - j);
         double l = iLow(_Symbol, _Period, i - j);
         if(h > futureHigh) futureHigh = h;
         if(l < futureLow) futureLow = l;
      }
      
      double maxUpMove = futureHigh - close;
      double maxDownMove = close - futureLow;
      
      //--- เขียนข้อมูลลงไฟล์
      // Time and Price data
      FileWrite(file, TimeToString(time, TIME_DATE|TIME_MINUTES), 
                      open, high, low, close, volume);
      
      // Features
      for(int f = 0; f < ArraySize(featureVector); f++)
      {
         FileWrite(file, featureVector[f]);
      }
      
      // Targets
      FileWrite(file, futureClose, futureChange, futureChangePercent, 
                      futureDirection, maxUpMove, maxDownMove);
      
      recordCount++;
      
      //--- แสดงความคืบหน้า
      if(recordCount % 100 == 0)
      {
         double progress = (startBar - i) * 100.0 / totalBars;
         int elapsed = (int)(TimeCurrent() - startTime);
         int estimated = (progress > 0) ? (int)(elapsed / progress * 100) : 0;
         int remaining = estimated - elapsed;
         
         Print(StringFormat("⏳ Progress: %.1f%% | Records: %d | Errors: %d | Remaining: %ds", 
               progress, recordCount, errorCount, remaining));
      }
   }
   
   //--- ปิดไฟล์
   FileClose(file);
   delete features;
   
   //--- สรุปผล
   Print("\n╔════════════════════════════════════════════════════════════╗");
   Print("║  ✅ DATA COLLECTION COMPLETED                             ║");
   Print("╠════════════════════════════════════════════════════════════╣");
   Print("║  📁 File: ", OutputFile);
   Print("║  📊 Records: ", recordCount);
   Print("║  ❌ Errors: ", errorCount);
   Print("║  ⏱️ Time: ", (int)(TimeCurrent() - startTime), "s");
   Print("╚════════════════════════════════════════════════════════════╝");
   Print("\n💡 ขั้นตอนต่อไป:");
   Print("  1. คัดลอกไฟล์ ", OutputFile, " จากโฟลเดอร์ MQL5/Files");
   Print("  2. รัน Python script: python train_ai_models.py");
   Print("  3. นำโมเดลที่ train แล้วกลับมาใช้กับ EA");
}

//+------------------------------------------------------------------+
//| Write CSV Headers                                                 |
//+------------------------------------------------------------------+
void WriteHeaders(int fileHandle, FeatureExtractor* feat)
{
   // Time and Price headers
   string headers = "Time,Open,High,Low,Close,Volume,";
   
   // Feature headers
   string featureNames[];
   feat.GetFeatureNames(featureNames);
   
   for(int i = 0; i < ArraySize(featureNames); i++)
   {
      headers += featureNames[i];
      if(i < ArraySize(featureNames) - 1)
         headers += ",";
   }
   
   // Target headers
   headers += ",Future_Close,Future_Change,Future_Change_Pct,Future_Direction,Max_Up_Move,Max_Down_Move";
   
   FileWriteString(fileHandle, headers + "\n");
}
//+------------------------------------------------------------------+
