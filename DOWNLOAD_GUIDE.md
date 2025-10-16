# 📥 คู่มือดาวน์โหลดและติดตั้ง

## 📋 รายการไฟล์ที่ต้องดาวน์โหลด

### ✅ สำหรับ MQL5 (จำเป็น)

#### 1. Expert Advisor หลัก
```
📁 Experts/AI_NeuralNetwork_EA.mq5
```
**วิธีดาวน์โหลด:** คัดลอกโค้ดทั้งหมดจากไฟล์นี้

---

#### 2. Libraries (จำเป็น!)
```
📁 Includes/NeuralNetwork.mqh
📁 Includes/TradingFeatures.mqh
```
**วิธีดาวน์โหลด:** คัดลอกโค้ดทั้งหมดจากทั้ง 2 ไฟล์

---

#### 3. Data Collector Script (ถ้าจะใช้ Python)
```
📁 Scripts/AI_DataCollector.mq5
```
**วิธีดาวน์โหลด:** คัดลอกโค้ดทั้งหมด

---

### 🐍 สำหรับ Python (ถ้าต้องการใช้ Advanced ML)

```
📁 Python/train_ai_models.py
📁 Python/convert_to_onnx.py
📁 Python/requirements.txt
```

---

### 📚 เอกสาร (แนะนำ)

```
📄 README.md
📄 QUICK_START.md
📄 PROJECT_SUMMARY.md
```

---

## 🚀 วิธีติดตั้งใน MetaTrader 5

### ขั้นตอนที่ 1: เปิดโฟลเดอร์ MQL5

**วิธีที่ 1:** จาก MetaTrader 5
1. เปิด MT5
2. กด **File → Open Data Folder**
3. เปิดโฟลเดอร์ **MQL5**

**วิธีที่ 2:** หาเองใน Windows
```
C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[InstanceID]\MQL5\
```

---

### ขั้นตอนที่ 2: สร้างโฟลเดอร์

สร้างโฟลเดอร์ (ถ้ายังไม่มี):

```
MQL5/
├── Experts/           ← ถ้าไม่มีให้สร้าง
├── Scripts/           ← ถ้าไม่มีให้สร้าง
└── Include/
    └── Includes/      ← สร้างโฟลเดอร์ Includes ใน Include
```

---

### ขั้นตอนที่ 3: คัดลอกไฟล์

#### A. Expert Advisor
```
คัดลอก: Experts/AI_NeuralNetwork_EA.mq5
ไปวางที่: MQL5/Experts/AI_NeuralNetwork_EA.mq5
```

#### B. Libraries (สำคัญมาก!)
```
คัดลอก: Includes/NeuralNetwork.mqh
ไปวางที่: MQL5/Include/Includes/NeuralNetwork.mqh

คัดลอก: Includes/TradingFeatures.mqh
ไปวางที่: MQL5/Include/Includes/TradingFeatures.mqh
```

#### C. Script (ถ้าต้องการ)
```
คัดลอก: Scripts/AI_DataCollector.mq5
ไปวางที่: MQL5/Scripts/AI_DataCollector.mq5
```

---

### ขั้นตอนที่ 4: คอมไพล์ไฟล์

1. เปิด **MetaEditor** (กด F4 ใน MT5)
2. ไปที่ **Navigator** → **Experts**
3. คลิกขวาที่ `AI_NeuralNetwork_EA.mq5`
4. เลือก **Compile** (หรือกด F7)
5. ตรวจสอบว่าไม่มี Error ในแท็บ **Toolbox**

---

### ขั้นตอนที่ 5: ใช้งาน EA

1. กลับไปที่ MT5
2. เปิดชาร์ต (เช่น EURUSD H1)
3. ไปที่ **Navigator** → **Expert Advisors**
4. **ลาก** `AI_NeuralNetwork_EA` ไปวางบนชาร์ต
5. ตั้งค่าพารามิเตอร์
6. กด **OK**
7. เริ่มเทรด! 🎉

---

## 📝 Checklist การติดตั้ง

- [ ] ดาวน์โหลด AI_NeuralNetwork_EA.mq5
- [ ] ดาวน์โหลด NeuralNetwork.mqh
- [ ] ดาวน์โหลด TradingFeatures.mqh
- [ ] วางไฟล์ในโฟลเดอร์ที่ถูกต้อง
- [ ] คอมไพล์ไฟล์ใน MetaEditor
- [ ] ไม่มี Error
- [ ] ลาก EA ไปบนชาร์ต
- [ ] ตั้งค่าพารามิเตอร์
- [ ] เริ่มใช้งาน!

---

## 🐍 สำหรับ Python (ถ้าต้องการ)

### ขั้นตอนที่ 1: สร้างโฟลเดอร์

```bash
mkdir ai-trading-python
cd ai-trading-python
```

### ขั้นตอนที่ 2: ดาวน์โหลดไฟล์ Python

```
Python/train_ai_models.py
Python/convert_to_onnx.py
Python/requirements.txt
```

### ขั้นตอนที่ 3: Setup Environment

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

---

## ⚠️ ปัญหาที่อาจพบ

### Error: Cannot open include file 'Includes\NeuralNetwork.mqh'

**สาเหตุ:** วางไฟล์ .mqh ผิดที่

**แก้ไข:**
```
ตรวจสอบว่าไฟล์อยู่ที่:
MQL5/Include/Includes/NeuralNetwork.mqh
MQL5/Include/Includes/TradingFeatures.mqh

ไม่ใช่:
MQL5/Include/NeuralNetwork.mqh  ← ผิด!
```

---

### Error: Compilation failed

**แก้ไข:**
1. ตรวจสอบว่าคัดลอกโค้ดครบ
2. ตรวจสอบว่า libraries อยู่ในโฟลเดอร์ที่ถูกต้อง
3. Restart MetaEditor
4. คอมไพล์ใหม่

---

### EA ไม่ปรากฏใน Navigator

**แก้ไข:**
1. Restart MT5
2. ตรวจสอบว่าคอมไพล์สำเร็จ (มีไฟล์ .ex5)
3. Refresh Navigator (คลิกขวา → Refresh)

---

## 💡 เคล็ดลับ

1. **ตั้งชื่อไฟล์ให้ตรง** - ห้ามเปลี่ยนชื่อไฟล์
2. **วางในโฟลเดอร์ที่ถูกต้อง** - ตรวจสอบ path ให้ดี
3. **คอมไพล์ก่อนใช้งาน** - ต้องคอมไพล์ทุกครั้งที่แก้ไข
4. **เปิด AutoTrading** - กดปุ่ม AutoTrading ใน MT5
5. **ทดสอบบน Demo** - อย่าใช้เงินจริงทันที!

---

## 📞 ต้องการความช่วยเหลือ?

หากมีปัญหาในการติดตั้ง:
1. ตรวจสอบ Error message ในแท็บ Toolbox
2. ดู log ในแท็บ Experts Journal
3. อ่าน QUICK_START.md
4. ถามได้เลย!

---

<div align="center">

**🎉 ติดตั้งเสร็จแล้วเริ่มเทรดได้เลย!**

</div>
