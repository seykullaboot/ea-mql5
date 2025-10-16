//+------------------------------------------------------------------+
//|                                           TradingFeatures.mqh    |
//|                                Feature Engineering Library        |
//|                     สำหรับสร้าง features สำหรับ AI Trading       |
//+------------------------------------------------------------------+
#property copyright "EA-MQL5 AI Trading"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Feature Extractor Class                                           |
//+------------------------------------------------------------------+
class FeatureExtractor
{
private:
   // Indicator handles
   int m_handleRSI;
   int m_handleMACD;
   int m_handleATR;
   int m_handleBB;
   int m_handleStoch;
   int m_handleADX;
   int m_handleCCI;
   int m_handleMA_Fast;
   int m_handleMA_Slow;
   
   // Buffers
   double m_rsi[];
   double m_macd[], m_signal[];
   double m_atr[];
   double m_bbUpper[], m_bbMiddle[], m_bbLower[];
   double m_stochMain[], m_stochSignal[];
   double m_adxMain[], m_adxPlus[], m_adxMinus[];
   double m_cci[];
   double m_maFast[], m_maSlow[];
   
   string m_symbol;
   ENUM_TIMEFRAMES m_period;
   
public:
   FeatureExtractor()
   {
      m_symbol = _Symbol;
      m_period = _Period;
      
      // ตั้งค่า arrays เป็น time series
      ArraySetAsSeries(m_rsi, true);
      ArraySetAsSeries(m_macd, true);
      ArraySetAsSeries(m_signal, true);
      ArraySetAsSeries(m_atr, true);
      ArraySetAsSeries(m_bbUpper, true);
      ArraySetAsSeries(m_bbMiddle, true);
      ArraySetAsSeries(m_bbLower, true);
      ArraySetAsSeries(m_stochMain, true);
      ArraySetAsSeries(m_stochSignal, true);
      ArraySetAsSeries(m_adxMain, true);
      ArraySetAsSeries(m_adxPlus, true);
      ArraySetAsSeries(m_adxMinus, true);
      ArraySetAsSeries(m_cci, true);
      ArraySetAsSeries(m_maFast, true);
      ArraySetAsSeries(m_maSlow, true);
   }
   
   ~FeatureExtractor()
   {
      ReleaseIndicators();
   }
   
   // สร้าง indicators
   bool Initialize()
   {
      Print("📊 กำลังสร้าง indicators สำหรับ features...");
      
      m_handleRSI = iRSI(m_symbol, m_period, 14, PRICE_CLOSE);
      m_handleMACD = iMACD(m_symbol, m_period, 12, 26, 9, PRICE_CLOSE);
      m_handleATR = iATR(m_symbol, m_period, 14);
      m_handleBB = iBands(m_symbol, m_period, 20, 0, 2.0, PRICE_CLOSE);
      m_handleStoch = iStochastic(m_symbol, m_period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
      m_handleADX = iADX(m_symbol, m_period, 14);
      m_handleCCI = iCCI(m_symbol, m_period, 14, PRICE_TYPICAL);
      m_handleMA_Fast = iMA(m_symbol, m_period, 20, 0, MODE_EMA, PRICE_CLOSE);
      m_handleMA_Slow = iMA(m_symbol, m_period, 50, 0, MODE_EMA, PRICE_CLOSE);
      
      if(m_handleRSI == INVALID_HANDLE || m_handleMACD == INVALID_HANDLE ||
         m_handleATR == INVALID_HANDLE || m_handleBB == INVALID_HANDLE ||
         m_handleStoch == INVALID_HANDLE || m_handleADX == INVALID_HANDLE ||
         m_handleCCI == INVALID_HANDLE || m_handleMA_Fast == INVALID_HANDLE ||
         m_handleMA_Slow == INVALID_HANDLE)
      {
         Print("❌ ไม่สามารถสร้าง indicators ได้");
         return false;
      }
      
      Print("✅ สร้าง indicators สำเร็จ");
      return true;
   }
   
   // ปล่อย indicators
   void ReleaseIndicators()
   {
      if(m_handleRSI != INVALID_HANDLE) IndicatorRelease(m_handleRSI);
      if(m_handleMACD != INVALID_HANDLE) IndicatorRelease(m_handleMACD);
      if(m_handleATR != INVALID_HANDLE) IndicatorRelease(m_handleATR);
      if(m_handleBB != INVALID_HANDLE) IndicatorRelease(m_handleBB);
      if(m_handleStoch != INVALID_HANDLE) IndicatorRelease(m_handleStoch);
      if(m_handleADX != INVALID_HANDLE) IndicatorRelease(m_handleADX);
      if(m_handleCCI != INVALID_HANDLE) IndicatorRelease(m_handleCCI);
      if(m_handleMA_Fast != INVALID_HANDLE) IndicatorRelease(m_handleMA_Fast);
      if(m_handleMA_Slow != INVALID_HANDLE) IndicatorRelease(m_handleMA_Slow);
   }
   
   // Extract features
   bool ExtractFeatures(double &features[], int shift = 0)
   {
      // คัดลอกข้อมูล indicators
      if(!CopyIndicatorData(shift))
         return false;
      
      // ข้อมูล price
      double close[], open[], high[], low[];
      long volume[];
      ArraySetAsSeries(close, true);
      ArraySetAsSeries(open, true);
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(volume, true);
      
      if(CopyClose(m_symbol, m_period, shift, 10, close) < 10 ||
         CopyOpen(m_symbol, m_period, shift, 10, open) < 10 ||
         CopyHigh(m_symbol, m_period, shift, 10, high) < 10 ||
         CopyLow(m_symbol, m_period, shift, 10, low) < 10 ||
         CopyTickVolume(m_symbol, m_period, shift, 10, volume) < 10)
         return false;
      
      // สร้าง feature vector
      int idx = 0;
      ArrayResize(features, 30); // จำนวน features ทั้งหมด
      
      // 1. RSI (normalized 0-1)
      features[idx++] = m_rsi[0] / 100.0;
      
      // 2-3. MACD
      features[idx++] = NormalizeValue(m_macd[0], -0.001, 0.001);
      features[idx++] = NormalizeValue(m_macd[0] - m_signal[0], -0.001, 0.001);
      
      // 4. ATR (normalized)
      double avgATR = (m_atr[0] + m_atr[1] + m_atr[2]) / 3.0;
      features[idx++] = (avgATR > 0) ? m_atr[0] / (avgATR * 2.0) : 0.5;
      
      // 5-6. Bollinger Bands
      double bbWidth = m_bbUpper[0] - m_bbLower[0];
      features[idx++] = (bbWidth > 0) ? (close[0] - m_bbLower[0]) / bbWidth : 0.5;
      features[idx++] = NormalizeValue(bbWidth, 0, SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 1000);
      
      // 7-8. Stochastic
      features[idx++] = m_stochMain[0] / 100.0;
      features[idx++] = NormalizeValue(m_stochMain[0] - m_stochSignal[0], -100, 100);
      
      // 9-11. ADX
      features[idx++] = m_adxMain[0] / 100.0;
      features[idx++] = m_adxPlus[0] / 100.0;
      features[idx++] = m_adxMinus[0] / 100.0;
      
      // 12. CCI
      features[idx++] = NormalizeValue(m_cci[0], -200, 200);
      
      // 13-14. Moving Averages
      features[idx++] = (close[0] > m_maFast[0]) ? 1.0 : 0.0;
      features[idx++] = (m_maFast[0] > m_maSlow[0]) ? 1.0 : 0.0;
      
      // 15-17. Price Patterns
      features[idx++] = NormalizeValue(close[0] - close[1], -SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 100, 
                                       SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 100);
      features[idx++] = NormalizeValue(close[0] - close[4], -SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 500,
                                       SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 500);
      features[idx++] = NormalizeValue(high[0] - low[0], 0, SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 200);
      
      // 18-20. Candle Patterns
      double bodySize = MathAbs(close[0] - open[0]);
      double totalSize = high[0] - low[0];
      features[idx++] = (totalSize > 0) ? bodySize / totalSize : 0.5;
      features[idx++] = (close[0] > open[0]) ? 1.0 : 0.0; // Bullish/Bearish
      features[idx++] = (totalSize > 0) ? (close[0] - low[0]) / totalSize : 0.5;
      
      // 21-23. Volume
      double avgVol = (volume[0] + volume[1] + volume[2] + volume[3] + volume[4]) / 5.0;
      features[idx++] = (avgVol > 0) ? volume[0] / avgVol : 1.0;
      features[idx++] = (avgVol > 0) ? (volume[0] > avgVol) ? 1.0 : 0.0 : 0.5;
      features[idx++] = NormalizeValue(volume[0] - volume[1], -avgVol, avgVol);
      
      // 24-26. Price Position
      double high10 = high[ArrayMaximum(high, 0, 10)];
      double low10 = low[ArrayMinimum(low, 0, 10)];
      features[idx++] = (high10 - low10 > 0) ? (close[0] - low10) / (high10 - low10) : 0.5;
      features[idx++] = (close[0] == high10) ? 1.0 : 0.0;
      features[idx++] = (close[0] == low10) ? 1.0 : 0.0;
      
      // 27-30. Momentum
      features[idx++] = NormalizeValue(close[0] - close[3], -SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 300,
                                       SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 300);
      features[idx++] = NormalizeValue(close[0] - close[5], -SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 500,
                                       SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 500);
      features[idx++] = NormalizeValue(close[0] - close[10], -SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 1000,
                                       SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 1000);
      features[idx++] = (close[9] > 0) ? (close[0] - close[9]) / close[9] : 0.0;
      
      return true;
   }
   
   // Get feature count
   int GetFeatureCount()
   {
      return 30;
   }
   
   // Get feature names
   void GetFeatureNames(string &names[])
   {
      ArrayResize(names, 30);
      names[0] = "RSI";
      names[1] = "MACD";
      names[2] = "MACD_Diff";
      names[3] = "ATR";
      names[4] = "BB_Position";
      names[5] = "BB_Width";
      names[6] = "Stoch_Main";
      names[7] = "Stoch_Diff";
      names[8] = "ADX";
      names[9] = "ADX_Plus";
      names[10] = "ADX_Minus";
      names[11] = "CCI";
      names[12] = "Price_Above_MA_Fast";
      names[13] = "MA_Fast_Above_Slow";
      names[14] = "Price_Change_1";
      names[15] = "Price_Change_4";
      names[16] = "Candle_Range";
      names[17] = "Body_Ratio";
      names[18] = "Bullish_Bearish";
      names[19] = "Close_Position";
      names[20] = "Volume_Ratio";
      names[21] = "Volume_Above_Avg";
      names[22] = "Volume_Change";
      names[23] = "Price_Position_10";
      names[24] = "At_High_10";
      names[25] = "At_Low_10";
      names[26] = "Momentum_3";
      names[27] = "Momentum_5";
      names[28] = "Momentum_10";
      names[29] = "Return_10";
   }
   
private:
   // คัดลอกข้อมูล indicators
   bool CopyIndicatorData(int shift)
   {
      if(CopyBuffer(m_handleRSI, 0, shift, 3, m_rsi) < 3) return false;
      if(CopyBuffer(m_handleMACD, 0, shift, 3, m_macd) < 3) return false;
      if(CopyBuffer(m_handleMACD, 1, shift, 3, m_signal) < 3) return false;
      if(CopyBuffer(m_handleATR, 0, shift, 3, m_atr) < 3) return false;
      if(CopyBuffer(m_handleBB, 0, shift, 1, m_bbUpper) < 1) return false;
      if(CopyBuffer(m_handleBB, 1, shift, 1, m_bbMiddle) < 1) return false;
      if(CopyBuffer(m_handleBB, 2, shift, 1, m_bbLower) < 1) return false;
      if(CopyBuffer(m_handleStoch, 0, shift, 3, m_stochMain) < 3) return false;
      if(CopyBuffer(m_handleStoch, 1, shift, 3, m_stochSignal) < 3) return false;
      if(CopyBuffer(m_handleADX, 0, shift, 1, m_adxMain) < 1) return false;
      if(CopyBuffer(m_handleADX, 1, shift, 1, m_adxPlus) < 1) return false;
      if(CopyBuffer(m_handleADX, 2, shift, 1, m_adxMinus) < 1) return false;
      if(CopyBuffer(m_handleCCI, 0, shift, 1, m_cci) < 1) return false;
      if(CopyBuffer(m_handleMA_Fast, 0, shift, 1, m_maFast) < 1) return false;
      if(CopyBuffer(m_handleMA_Slow, 0, shift, 1, m_maSlow) < 1) return false;
      
      return true;
   }
   
   // Normalize value
   double NormalizeValue(double value, double min, double max)
   {
      if(max == min) return 0.5;
      double normalized = (value - min) / (max - min);
      return MathMax(0, MathMin(1, normalized));
   }
};
//+------------------------------------------------------------------+
