#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
╔════════════════════════════════════════════════════════════╗
║  📦 MODEL TO ONNX CONVERTER                               ║
║  แปลงโมเดล Python เป็น ONNX format สำหรับใช้ใน MQL5      ║
╚════════════════════════════════════════════════════════════╝
"""

import joblib
import numpy as np
import onnx
import onnxruntime as ort
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType
import os

class ModelConverter:
    """แปลงโมเดล ML เป็น ONNX format"""
    
    def __init__(self, models_dir='models', output_dir='onnx_models'):
        self.models_dir = models_dir
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
    
    def convert_sklearn_model(self, model_name):
        """
        แปลงโมเดล scikit-learn เป็น ONNX
        
        Args:
            model_name: ชื่อโมเดล (เช่น 'random_forest', 'xgboost')
        """
        print(f"\n{'='*60}")
        print(f"📦 Converting {model_name} to ONNX...")
        print(f"{'='*60}")
        
        # โหลดโมเดล
        model_file = f"{self.models_dir}/{model_name}_model.pkl"
        if not os.path.exists(model_file):
            print(f"❌ ไม่พบไฟล์: {model_file}")
            return False
        
        model = joblib.load(model_file)
        print(f"✅ โหลดโมเดล: {model_file}")
        
        # โหลด feature names เพื่อหาจำนวน input features
        feature_names_file = f"{self.models_dir}/feature_names.pkl"
        if os.path.exists(feature_names_file):
            feature_names = joblib.load(feature_names_file)
            n_features = len(feature_names)
        else:
            print("⚠️ ไม่พบ feature_names.pkl - ใช้ค่าเริ่มต้น 30 features")
            n_features = 30
        
        print(f"📊 จำนวน features: {n_features}")
        
        # กำหนด input type
        initial_type = [('float_input', FloatTensorType([None, n_features]))]
        
        try:
            # แปลงเป็น ONNX
            onnx_model = convert_sklearn(
                model,
                initial_types=initial_type,
                target_opset=12
            )
            
            # บันทึก
            output_file = f"{self.output_dir}/{model_name}.onnx"
            with open(output_file, "wb") as f:
                f.write(onnx_model.SerializeToString())
            
            print(f"✅ บันทึก ONNX model: {output_file}")
            
            # ทดสอบ
            self.test_onnx_model(output_file, n_features)
            
            return True
            
        except Exception as e:
            print(f"❌ เกิดข้อผิดพลาด: {str(e)}")
            return False
    
    def test_onnx_model(self, onnx_file, n_features):
        """ทดสอบ ONNX model"""
        print(f"\n🧪 Testing ONNX model...")
        
        try:
            # โหลดโมเดล
            session = ort.InferenceSession(onnx_file)
            
            # สร้างข้อมูลทดสอบ
            test_input = np.random.rand(1, n_features).astype(np.float32)
            
            # ทำนาย
            input_name = session.get_inputs()[0].name
            output_name = session.get_outputs()[0].name
            result = session.run([output_name], {input_name: test_input})
            
            print(f"✅ ONNX model ใช้งานได้!")
            print(f"   Input shape: {test_input.shape}")
            print(f"   Output: {result[0]}")
            
            # แสดงข้อมูลโมเดล
            print(f"\n📋 Model Info:")
            print(f"   Inputs: {[i.name for i in session.get_inputs()]}")
            print(f"   Outputs: {[o.name for o in session.get_outputs()]}")
            
            return True
            
        except Exception as e:
            print(f"❌ การทดสอบล้มเหลว: {str(e)}")
            return False
    
    def convert_all(self):
        """แปลงโมเดลทั้งหมด"""
        print("\n" + "╔" + "="*58 + "╗")
        print("║" + " "*15 + "📦 ONNX CONVERTER" + " "*25 + "║")
        print("╚" + "="*58 + "╝")
        
        models_to_convert = [
            'random_forest',
            'xgboost',
            'lightgbm',
            'gradient_boosting'
        ]
        
        success_count = 0
        
        for model_name in models_to_convert:
            if self.convert_sklearn_model(model_name):
                success_count += 1
        
        print("\n" + "╔" + "="*58 + "╗")
        print(f"║  ✅ Converted {success_count}/{len(models_to_convert)} models successfully" + " "*(58-len(f"  ✅ Converted {success_count}/{len(models_to_convert)} models successfully")) + "║")
        print("╚" + "="*58 + "╝")
        
        if success_count > 0:
            print("\n💡 ขั้นตอนต่อไป:")
            print(f"  1. คัดลอกไฟล์ .onnx จาก {self.output_dir}/")
            print("  2. วางไฟล์ใน MQL5/Files/")
            print("  3. ใช้ ONNX Integration EA เพื่อโหลดและใช้โมเดล")

def main():
    """Main function"""
    converter = ModelConverter()
    converter.convert_all()

if __name__ == '__main__':
    main()
