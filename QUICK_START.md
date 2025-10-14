# ⚡ Quick Start Guide

เริ่มใช้งาน AI Trading System ภายใน 5 นาที!

---

## 🎯 สำหรับผู้เริ่มต้น (แนะนำ)

### ขั้นตอนที่ 1: ติดตั้งไฟล์

1. **Download** โปรเจ็กต์นี้
2. **คัดลอกไฟล์** ไปยัง MetaTrader 5:
   ```
   Experts/AI_NeuralNetwork_EA.mq5  → MQL5/Experts/
   Includes/NeuralNetwork.mqh       → MQL5/Include/Includes/
   Includes/TradingFeatures.mqh     → MQL5/Include/Includes/
   ```
3. **เปิด MetaEditor** (กด F4 ใน MT5)
4. **คอมไพล์** ไฟล์ `AI_NeuralNetwork_EA.mq5`

### ขั้นตอนที่ 2: ใช้งาน EA

1. **เปิด chart** (แนะนำ EURUSD H1)
2. **ลาก EA** จาก Navigator → Expert Advisors
3. **ตั้งค่า** ตามนี้:
   ```
   ═══ AI Settings ═══
   Enable AI: ✓
   Enable Learning: ✓
   Min Confidence: 0.60
   
   ═══ Risk Management ═══
   Use Auto Lot: ✓
   Risk Percent: 2.0
   Stop Loss: 100
   Take Profit: 200
   ```
4. **กด OK** และเริ่มเทรด!

### ขั้นตอนที่ 3: ตรวจสอบ

- ดูข้อมูลบน chart (prediction, confidence, win rate)
- ตรวจสอบ log ในแท็บ "Experts"
- รอ 1-2 วัน สังเกตผลลัพธ์

---

## 🐍 สำหรับผู้ใช้ Python (Advanced)

### ขั้นตอนที่ 1: Setup Python

```bash
cd Python/
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### ขั้นตอนที่ 2: เก็บข้อมูล

1. ใน MT5 รัน `Scripts/AI_DataCollector`
2. ตั้งค่า:
   - Start Date: 2023.01.01
   - End Date: 2024.12.31
3. รอจนเสร็จ (ประมาณ 2-5 นาที)
4. คัดลอก `ai_training_data.csv` จาก `MQL5/Files/` ไปที่ `Python/`

### ขั้นตอนที่ 3: Train Models

```bash
cd Python/
python train_ai_models.py
```

รอ 5-15 นาที (ขึ้นกับข้อมูล)

### ขั้นตอนที่ 4: ดูผลลัพธ์

```bash
# ดู model comparison
cat reports/model_comparison.csv

# ดูกราฟ
# เปิดไฟล์ใน plots/ folder
```

---

## 📊 ตัวอย่างการใช้งาน

### Scenario 1: ผู้เริ่มต้นต้องการลอง AI Trading

```
1. ติดตั้ง AI_NeuralNetwork_EA
2. ใช้ค่าเริ่มต้น
3. ทดสอบบน demo account 1 สัปดาห์
4. ถ้าผลดี → ใช้จริง (risk 1-2%)
```

### Scenario 2: นักเทรดต้องการ optimize strategy

```
1. เก็บข้อมูล 2-3 ปี
2. Train หลายโมเดลด้วย Python
3. เลือกโมเดลที่ดีที่สุด
4. Backtest ใน Strategy Tester
5. Forward test 1 เดือน
6. Deploy จริง
```

### Scenario 3: Developer ต้องการ customize

```
1. แก้ไข Includes/TradingFeatures.mqh (เพิ่ม features)
2. ปรับ network architecture ใน EA
3. Train ใหม่
4. ทดสอบและเปรียบเทียบ
```

---

## ⚙️ การตั้งค่าตาม Trading Style

### Day Trading (M15-H1)

```
Training Frequency: 20-30
Min Confidence: 0.55
Stop Loss: 50-100
Take Profit: 100-200
Risk: 1-2%
```

### Swing Trading (H1-H4)

```
Training Frequency: 50-100
Min Confidence: 0.60
Stop Loss: 100-200
Take Profit: 200-400
Risk: 2-3%
```

### Position Trading (H4-D1)

```
Training Frequency: 100-200
Min Confidence: 0.65
Stop Loss: 200-500
Take Profit: 400-1000
Risk: 1-2%
```

---

## ✅ Checklist

ก่อนเริ่มเทรดจริง ตรวจสอบ:

- [ ] ทดสอบบน demo account แล้ว
- [ ] ดู win rate > 50%
- [ ] เข้าใจการทำงานของ EA
- [ ] ตั้ง risk management ที่เหมาะสม
- [ ] มี stop loss ทุกออเดอร์
- [ ] เตรียมพร้อมรับผลขาดทุน
- [ ] ไม่ลงทุนเกินกว่าที่สูญเสียได้

---

## 🆘 ต้องการความช่วยเหลือ?

1. อ่าน [README.md](README.md) ฉบับเต็ม
2. ตรวจสอบ [FAQ](README.md#-faq)
3. ดู [Troubleshooting](README.md#-การแก้ไขปัญหา)
4. เปิด Issue ใน GitHub

---

## 🎓 เรียนรู้เพิ่มเติม

- [MQL5 Documentation](https://www.mql5.com/en/docs)
- [Scikit-learn Guide](https://scikit-learn.org/stable/user_guide.html)
- [XGBoost Documentation](https://xgboost.readthedocs.io/)

---

<div align="center">

**🚀 Happy Trading!**

</div>
