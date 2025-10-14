# EA-MQL5: Moving Average Crossover Expert Advisor

Expert Advisor สำหรับ MetaTrader 5 ที่ใช้กลยุทธ์ Moving Average Crossover

## 📋 รายละเอียด

Expert Advisor นี้ใช้กลยุทธ์การตัดกันของเส้น Moving Average 2 เส้น:
- **สัญญาณซื้อ (BUY)**: เมื่อ MA เร็วตัด MA ช้าขึ้น (Golden Cross)
- **สัญญาณขาย (SELL)**: เมื่อ MA เร็วตัด MA ช้าลง (Death Cross)

## ✨ คุณสมบัติ

- ✅ กลยุทธ์ Moving Average Crossover ที่พิสูจน์แล้ว
- ✅ ระบบจัดการความเสี่ยงอัตโนมัติ (Auto Lot Sizing)
- ✅ Stop Loss และ Take Profit ปรับแต่งได้
- ✅ ปิดออเดอร์เก่าอัตโนมัติเมื่อมีสัญญาณกลับตัว
- ✅ คอมเมนต์เป็นภาษาไทยทั้งหมด
- ✅ ปรับแต่งพารามิเตอร์ได้ง่าย

## 📦 การติดตั้ง

1. ดาวน์โหลดไฟล์ `MA_Crossover_EA.mq5`
2. คัดลอกไฟล์ไปที่โฟลเดอร์ MQL5 ของคุณ:
   - Windows: `C:\Users\[Username]\AppData\Roaming\MetaQuotes\Terminal\[Instance]\MQL5\Experts\`
   - macOS: `~/Library/Application Support/MetaQuotes/Terminal/[Instance]/MQL5/Experts/`
3. เปิด MetaEditor และคอมไพล์ไฟล์
4. Restart MetaTrader 5
5. ลาก EA จาก Navigator ไปยังชาร์ตที่ต้องการ

## ⚙️ การตั้งค่าพารามิเตอร์

### Moving Average Settings
- **FastMA_Period** (20): ช่วงเวลาของ MA เร็ว
- **SlowMA_Period** (50): ช่วงเวลาของ MA ช้า
- **MA_Method**: วิธีคำนวณ (SMA, EMA, SMMA, LWMA)
- **MA_Price**: ราคาที่ใช้คำนวณ (Close, Open, High, Low, etc.)

### Risk Management Settings
- **LotSize** (0.01): ขนาดล็อตคงที่ (เมื่อปิด UseAutoLot)
- **UseAutoLot** (true): ใช้การคำนวณล็อตอัตโนมัติตามความเสี่ยง
- **RiskPercent** (2.0): เปอร์เซ็นต์ความเสี่ยงต่อการเทรด
- **StopLoss** (100): Stop Loss เป็น points
- **TakeProfit** (200): Take Profit เป็น points

### General Settings
- **MagicNumber** (12345): หมายเลขประจำตัว EA
- **TradeComment**: คอมเมนต์ในออเดอร์
- **Slippage** (10): Slippage ที่ยอมรับได้

## 📊 กลยุทธ์การเทรด

1. EA จะรอให้มี Bar ใหม่เกิดขึ้น
2. คำนวณค่า Moving Average ทั้ง 2 เส้น
3. ตรวจสอบการตัดกัน (Crossover):
   - **Golden Cross**: MA เร็ว > MA ช้า (จากที่เคยต่ำกว่า) → เปิด BUY
   - **Death Cross**: MA เร็ว < MA ช้า (จากที่เคยสูงกว่า) → เปิด SELL
4. ปิดออเดอร์เก่าทิศทางตรงข้ามอัตโนมัติ
5. คำนวณขนาดล็อตตามระดับความเสี่ยงที่กำหนด

## 💡 คำแนะนำการใช้งาน

### สำหรับผู้เริ่มต้น
- ใช้ค่าพารามิเตอร์เริ่มต้น
- เปิด **UseAutoLot = true** 
- ตั้ง **RiskPercent = 1-2%** เท่านั้น
- ทดสอบบน Demo Account ก่อน

### สำหรับผู้มีประสบการณ์
- ปรับค่า MA Periods ให้เหมาะกับ Timeframe และคู่เงิน
- ทดสอบหาค่า StopLoss และ TakeProfit ที่เหมาะสม
- Backtest บนข้อมูลในอดีตก่อนใช้งานจริง

### Timeframes ที่แนะนำ
- **H1 (1 ชั่วโมง)**: เหมาะสำหรับ Swing Trading
- **H4 (4 ชั่วโมง)**: เหมาะสำหรับ Position Trading
- **D1 (รายวัน)**: เหมาะสำหรับ Long-term Trading

### คู่เงินที่แนะนำ
- EURUSD, GBPUSD, USDJPY (Majors)
- XAUUSD (Gold) - ปรับ StopLoss/TakeProfit ให้สูงขึ้น

## ⚠️ คำเตือน

- ⚠️ การเทรดมีความเสี่ยง อาจสูญเสียเงินทุนได้
- ⚠️ ทดสอบบน Demo Account ก่อนใช้กับเงินจริง
- ⚠️ ไม่มี EA ใดที่รับรองผลกำไร 100%
- ⚠️ ควรทำ Backtest และ Forward Test ก่อนใช้งาน
- ⚠️ ใช้ Money Management ที่เหมาะสม

## 🔧 การแก้ไขปัญหา

### EA ไม่เปิดออเดอร์
- ตรวจสอบว่าอนุญาต AutoTrading แล้ว (ปุ่ม AutoTrading บน Toolbar)
- ตรวจสอบว่า Lot Size ไม่ต่ำหรือสูงเกินกว่าที่โบรกเกอร์กำหนด
- ดูข้อความ Error ในแท็บ Experts

### EA เปิดออเดอร์บ่อยเกินไป
- เพิ่มค่า FastMA_Period และ SlowMA_Period
- ใช้ Timeframe ที่สูงขึ้น (เช่น H4, D1)

### EA ขาดทุน
- ทบทวนกลยุทธ์และพารามิเตอร์
- ปรับ StopLoss/TakeProfit ให้เหมาะสม
- ลดความเสี่ยง (RiskPercent)

## 📝 License

MIT License - ใช้งานได้อย่างอิสระ

## 🤝 การสนับสนุน

หากพบปัญหาหรือต้องการเพิ่มฟีเจอร์ กรุณาแจ้งผ่าน Issues

---

**หมายเหตุ**: EA นี้สร้างขึ้นเพื่อการศึกษาและการใช้งานส่วนบุคคล ผู้ใช้ควรทำความเข้าใจกลยุทธ์และทดสอบก่อนใช้งานจริง