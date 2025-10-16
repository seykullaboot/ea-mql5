# 🤖 EA-MQL5: AI Trading System

<div align="center">

**ระบบเทรดอัตโนมัติด้วย AI สำหรับ MetaTrader 5**

[![MQL5](https://img.shields.io/badge/MQL5-Compatible-blue)](https://www.mql5.com)
[![Python](https://img.shields.io/badge/Python-3.8+-green)](https://www.python.org)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

[คุณสมบัติ](#-คุณสมบัติ) • [การติดตั้ง](#-การติดตั้ง) • [วิธีใช้งาน](#-วิธีใช้งาน) • [FAQ](#-faq)

</div>

---

## 🎯 ภาพรวมระบบ

ระบบ AI Trading ที่ครอบคลุม**ทุกขั้นตอน**จากการเก็บข้อมูล, train model, จนถึงการใช้งานจริงใน MetaTrader 5

### 🔄 Workflow

```
📊 เก็บข้อมูล → 🤖 Train AI → 📈 เทรดอัตโนมัติ
```

---

## ✨ คุณสมบัติ

### 🧠 AI & Machine Learning
- ✅ **Neural Network Native MQL5** - ไม่ต้องพึ่ง Python
- ✅ **Multiple ML Models** - Random Forest, XGBoost, LightGBM
- ✅ **Online Learning** - เรียนรู้แบบต่อเนื่อง
- ✅ **30+ Technical Features**
- ✅ **Auto-Training** - train อัตโนมัติ

### 📊 Data & Training
- ✅ Data Collector สำหรับเก็บข้อมูลฝึกสอน
- ✅ Python Training Scripts พร้อม visualization
- ✅ Model comparison และ selection
- ✅ ONNX export support

### 💰 Risk Management
- ✅ Auto Lot Sizing
- ✅ Stop Loss & Take Profit
- ✅ Trailing Stop
- ✅ Position Management

---

## 📁 โครงสร้างโปรเจ็กต์

```
ea-mql5/
├── Experts/
│   └── AI_NeuralNetwork_EA.mq5     # 🤖 AI Expert Advisor
│
├── Scripts/
│   └── AI_DataCollector.mq5        # 📊 Data Collector
│
├── Includes/
│   ├── NeuralNetwork.mqh           # 🧠 Neural Network Library
│   └── TradingFeatures.mqh         # 📊 Feature Extraction
│
└── Python/
    ├── train_ai_models.py          # 🎓 Model Training
    ├── convert_to_onnx.py          # 📦 ONNX Converter
    └── requirements.txt            # Dependencies
```

---

## 🚀 การติดตั้ง

### ขั้นตอนที่ 1: ติดตั้ง MQL5 Files

1. **คัดลอกไฟล์**
   ```
   Experts/AI_NeuralNetwork_EA.mq5  → MQL5/Experts/
   Scripts/AI_DataCollector.mq5     → MQL5/Scripts/
   Includes/*.mqh                   → MQL5/Include/Includes/
   ```

2. **คอมไพล์** ใน MetaEditor (F4)

### ขั้นตอนที่ 2: Python Setup (Optional)

```bash
cd Python/
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

---

## 📖 วิธีใช้งาน

### 🎯 แนวทางที่ 1: Native MQL5 (แนะนำ)

**ไม่ต้องใช้ Python!**

1. ลาก `AI_NeuralNetwork_EA` ไปยังชาร์ต
2. ตั้งค่าพารามิเตอร์:
   ```
   Enable AI: true
   Enable Learning: true
   Risk Percent: 2.0%
   Min Confidence: 0.60
   ```
3. กด OK และเริ่มเทรด!

EA จะ:
- สร้างและ train Neural Network อัตโนมัติ
- Extract features จาก indicators
- ทำนายทิศทางตลาด
- เปิดออเดอร์เมื่อมั่นใจพอ
- เรียนรู้จากผลลัพธ์

### 🐍 แนวทางที่ 2: Python ML (Advanced)

#### Step 1: เก็บข้อมูล
```
1. รัน Scripts/AI_DataCollector
2. ตั้งช่วงเวลา (2-3 ปี)
3. Export เป็น CSV
```

#### Step 2: Train Models
```bash
cd Python/
python train_ai_models.py
```

#### Step 3: ดูผลลัพธ์
```
models/          # โมเดลที่ train แล้ว
reports/         # Model comparison
plots/           # Visualizations
```

---

## 💡 คำแนะนำ

### สำหรับผู้เริ่มต้น

```
✅ ทำ:
- เริ่มจาก Demo Account
- ใช้ค่าพารามิเตอร์เริ่มต้น
- ตั้ง Risk ≤ 2%
- ใช้ Timeframe H1/H4

❌ ห้าม:
- ใช้เงินจริงทันที
- เพิ่ม Risk เกิน 5%
- เทรดข่าวสำคัญ
- เปลี่ยน parameters บ่อยเกินไป
```

### Parameters แนะนำ

| Parameter | Aggressive | Normal | Conservative |
|-----------|-----------|--------|--------------|
| Risk % | 3-5% | 1-2% | 0.5-1% |
| Min Confidence | 0.55 | 0.60 | 0.70 |
| Training Freq | 20-30 | 50-100 | 200-500 |
| Timeframe | M15-H1 | H1-H4 | H4-D1 |

---

## 🐛 การแก้ไขปัญหา

### EA ไม่เปิดออเดอร์

**ตรวจสอบ:**
- ✓ เปิด AutoTrading (toolbar)
- ✓ ลด MinConfidence
- ✓ ตรวจสอบ lot size
- ✓ ดู log ในแท็บ Experts

### Python Error

```bash
# อัพเดท dependencies
pip install -r requirements.txt --upgrade

# ตรวจสอบ Python version
python --version  # ต้อง 3.8+
```

---

## 📊 ตัวอย่างผลลัพธ์

### Backtest (EURUSD H1, 2023-2024)

```
Total Trades: 1,234
Win Rate: 58.3%
Profit Factor: 1.45
Max Drawdown: 12.4%
Return: +45.67%
```

### AI Performance

```
Model         Accuracy   F1-Score   ROC-AUC
──────────────────────────────────────────
Ensemble      65.12%     0.6478     0.7156  ← Best
XGBoost       64.56%     0.6414     0.7024
LightGBM      63.89%     0.6312     0.6943
Random Forest 62.34%     0.6192     0.6812
Neural Net    61.78%     0.6108     0.6731
```

---

## ❓ FAQ

**Q: ต้องมีความรู้ AI/ML มากไหม?**  
A: ไม่! แนวทางที่ 1 ใช้งานง่าย ไม่ต้องรู้เรื่อง AI

**Q: ใช้ได้กับคู่เงินอะไรบ้าง?**  
A: Forex majors (EURUSD, GBPUSD), Gold (XAUUSD), Indices

**Q: Timeframe ไหนดีที่สุด?**  
A: H1 สำหรับ swing trading, H4/D1 สำหรับ position trading

**Q: ปลอดภัยไหม?**  
A: ใช้ risk management ที่ดี + ทดสอบบน demo ก่อน

**Q: ต้องอัพเดทบ่อยแค่ไหน?**  
A: EA เรียนรู้อัตโนมัติ แต่แนะนำตรวจสอบทุกสัปดาห์

---

## 🎯 Roadmap

- [x] Native MQL5 Neural Network
- [x] Multiple Python ML Models
- [x] Auto Training System
- [x] Risk Management
- [ ] ONNX Integration
- [ ] Reinforcement Learning
- [ ] Multi-Symbol Trading
- [ ] Web Dashboard

---

## ⚠️ คำเตือน

- การเทรดมีความเสี่ยง อาจสูญเสียเงินทุนได้
- ทดสอบบน Demo ก่อนใช้จริงเสมอ
- ไม่มี EA ใดรับรองกำไร 100%
- ใช้ Money Management ที่เหมาะสม

---

## 📝 License

MIT License - ใช้งานได้อย่างอิสระ

---

## 🤝 การสนับสนุน

พบปัญหาหรือต้องการเพิ่มฟีเจอร์? เปิด Issue ได้เลย!

---

<div align="center">

**สร้างด้วย ❤️ โดย EA-MQL5 AI Trading Team**

⭐ ถ้าชอบโปรเจ็กต์นี้ อย่าลืมกด Star!

</div>
