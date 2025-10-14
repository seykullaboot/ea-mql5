#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI Trading Model Training Script
สำหรับ train ML model จากข้อมูลที่เก็บจาก MQL5
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib
import matplotlib.pyplot as plt
import seaborn as sns

class AITradingTrainer:
    def __init__(self, data_file='training_data.csv'):
        """
        Initialize AI Trading Trainer
        
        Args:
            data_file: ไฟล์ CSV ที่ได้จาก AI_DataCollector.mq5
        """
        self.data_file = data_file
        self.model = None
        self.scaler = None
        self.feature_names = None
        
    def load_data(self):
        """โหลดข้อมูลจากไฟล์ CSV"""
        print(f"📂 กำลังโหลดข้อมูล: {self.data_file}")
        df = pd.read_csv(self.data_file)
        print(f"✅ โหลดข้อมูลสำเร็จ: {len(df)} rows")
        return df
    
    def prepare_features(self, df):
        """
        เตรียม features และ target สำหรับการ train
        
        Args:
            df: DataFrame ที่โหลดมา
            
        Returns:
            X, y: Features และ Target
        """
        print("🔧 กำลังเตรียม features...")
        
        # เลือก features ที่จะใช้
        feature_cols = [
            'RSI',
            'MACD', 'MACD_Signal', 'MACD_Diff',
            'ATR',
            'BB_Position', 'BB_Width',
            'Stoch_Main', 'Stoch_Signal',
            'Price_Change_1', 'Price_Change_4'
        ]
        
        # ตรวจสอบว่ามี columns ครบ
        missing_cols = [col for col in feature_cols if col not in df.columns]
        if missing_cols:
            raise ValueError(f"❌ ไม่พบ columns: {missing_cols}")
        
        # แยก features และ target
        X = df[feature_cols].values
        y = df['Future_Direction'].values
        
        # เก็บชื่อ features
        self.feature_names = feature_cols
        
        # ลบ NaN
        mask = ~np.isnan(X).any(axis=1) & ~np.isnan(y)
        X = X[mask]
        y = y[mask]
        
        print(f"✅ Features: {X.shape}")
        print(f"✅ Target distribution: Up={np.sum(y==1)}, Down={np.sum(y==0)}")
        
        return X, y
    
    def train_neural_network(self, X_train, y_train, X_test, y_test):
        """
        Train Neural Network Model
        
        Args:
            X_train, y_train: Training data
            X_test, y_test: Testing data
            
        Returns:
            Trained model
        """
        print("\n🧠 กำลัง train Neural Network...")
        
        model = MLPClassifier(
            hidden_layer_sizes=(100, 50, 25),
            activation='relu',
            solver='adam',
            alpha=0.0001,
            batch_size='auto',
            learning_rate='adaptive',
            learning_rate_init=0.001,
            max_iter=500,
            random_state=42,
            verbose=True,
            early_stopping=True,
            validation_fraction=0.1
        )
        
        model.fit(X_train, y_train)
        
        # ประเมินผล
        train_score = model.score(X_train, y_train)
        test_score = model.score(X_test, y_test)
        
        print(f"✅ Training Accuracy: {train_score:.4f}")
        print(f"✅ Testing Accuracy: {test_score:.4f}")
        
        return model
    
    def train_random_forest(self, X_train, y_train, X_test, y_test):
        """
        Train Random Forest Model
        
        Args:
            X_train, y_train: Training data
            X_test, y_test: Testing data
            
        Returns:
            Trained model
        """
        print("\n🌲 กำลัง train Random Forest...")
        
        model = RandomForestClassifier(
            n_estimators=200,
            max_depth=20,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42,
            n_jobs=-1,
            verbose=1
        )
        
        model.fit(X_train, y_train)
        
        # ประเมินผล
        train_score = model.score(X_train, y_train)
        test_score = model.score(X_test, y_test)
        
        print(f"✅ Training Accuracy: {train_score:.4f}")
        print(f"✅ Testing Accuracy: {test_score:.4f}")
        
        # Feature Importance
        self.plot_feature_importance(model)
        
        return model
    
    def train_gradient_boosting(self, X_train, y_train, X_test, y_test):
        """
        Train Gradient Boosting Model
        
        Args:
            X_train, y_train: Training data
            X_test, y_test: Testing data
            
        Returns:
            Trained model
        """
        print("\n🚀 กำลัง train Gradient Boosting...")
        
        model = GradientBoostingClassifier(
            n_estimators=200,
            learning_rate=0.1,
            max_depth=5,
            min_samples_split=5,
            min_samples_leaf=2,
            subsample=0.8,
            random_state=42,
            verbose=1
        )
        
        model.fit(X_train, y_train)
        
        # ประเมินผล
        train_score = model.score(X_train, y_train)
        test_score = model.score(X_test, y_test)
        
        print(f"✅ Training Accuracy: {train_score:.4f}")
        print(f"✅ Testing Accuracy: {test_score:.4f}")
        
        return model
    
    def evaluate_model(self, model, X_test, y_test):
        """
        ประเมินผลโมเดล
        
        Args:
            model: Trained model
            X_test, y_test: Testing data
        """
        print("\n📊 กำลังประเมินผลโมเดล...")
        
        y_pred = model.predict(X_test)
        
        # Accuracy
        accuracy = accuracy_score(y_test, y_pred)
        print(f"\n🎯 Accuracy: {accuracy:.4f}")
        
        # Classification Report
        print("\n📋 Classification Report:")
        print(classification_report(y_test, y_pred, 
                                   target_names=['Down', 'Up']))
        
        # Confusion Matrix
        cm = confusion_matrix(y_test, y_pred)
        self.plot_confusion_matrix(cm)
        
    def plot_feature_importance(self, model):
        """แสดง Feature Importance (สำหรับ tree-based models)"""
        if hasattr(model, 'feature_importances_'):
            importances = model.feature_importances_
            indices = np.argsort(importances)[::-1]
            
            plt.figure(figsize=(10, 6))
            plt.title('Feature Importance')
            plt.bar(range(len(importances)), importances[indices])
            plt.xticks(range(len(importances)), 
                      [self.feature_names[i] for i in indices], 
                      rotation=45, ha='right')
            plt.tight_layout()
            plt.savefig('feature_importance.png', dpi=300)
            print("💾 บันทึก feature importance: feature_importance.png")
            plt.close()
    
    def plot_confusion_matrix(self, cm):
        """แสดง Confusion Matrix"""
        plt.figure(figsize=(8, 6))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                   xticklabels=['Down', 'Up'],
                   yticklabels=['Down', 'Up'])
        plt.title('Confusion Matrix')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.tight_layout()
        plt.savefig('confusion_matrix.png', dpi=300)
        print("💾 บันทึก confusion matrix: confusion_matrix.png")
        plt.close()
    
    def save_model(self, model, model_name='ai_trading_model'):
        """
        บันทึกโมเดล
        
        Args:
            model: Trained model
            model_name: ชื่อไฟล์โมเดล
        """
        # บันทึก model
        model_file = f'{model_name}.pkl'
        joblib.dump(model, model_file)
        print(f"💾 บันทึกโมเดล: {model_file}")
        
        # บันทึก scaler
        if self.scaler is not None:
            scaler_file = f'{model_name}_scaler.pkl'
            joblib.dump(self.scaler, scaler_file)
            print(f"💾 บันทึก scaler: {scaler_file}")
    
    def train(self, model_type='neural_network', test_size=0.2):
        """
        Train โมเดล
        
        Args:
            model_type: ประเภทโมเดล ('neural_network', 'random_forest', 'gradient_boosting')
            test_size: สัดส่วนของ test set
        """
        # 1. โหลดข้อมูล
        df = self.load_data()
        
        # 2. เตรียม features
        X, y = self.prepare_features(df)
        
        # 3. แบ่งข้อมูล train/test
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )
        
        # 4. Normalize features
        print("🔧 กำลัง normalize features...")
        self.scaler = StandardScaler()
        X_train = self.scaler.fit_transform(X_train)
        X_test = self.scaler.transform(X_test)
        
        # 5. Train โมเดลตามที่เลือก
        if model_type == 'neural_network':
            self.model = self.train_neural_network(X_train, y_train, X_test, y_test)
        elif model_type == 'random_forest':
            self.model = self.train_random_forest(X_train, y_train, X_test, y_test)
        elif model_type == 'gradient_boosting':
            self.model = self.train_gradient_boosting(X_train, y_train, X_test, y_test)
        else:
            raise ValueError(f"ไม่รู้จักประเภทโมเดล: {model_type}")
        
        # 6. ประเมินผล
        self.evaluate_model(self.model, X_test, y_test)
        
        # 7. บันทึกโมเดล
        self.save_model(self.model, f'ai_trading_{model_type}')
        
        print("\n✅ Training เสร็จสิ้น!")
        return self.model

def main():
    """Main function"""
    print("=" * 60)
    print("🤖 AI Trading Model Training")
    print("=" * 60)
    
    # สร้าง trainer
    trainer = AITradingTrainer('training_data.csv')
    
    # Train โมเดลหลายแบบเพื่อเปรียบเทียบ
    models_to_train = ['neural_network', 'random_forest', 'gradient_boosting']
    
    print("\n📚 จะ train โมเดลทั้งหมด 3 แบบ:")
    print("  1. Neural Network")
    print("  2. Random Forest")
    print("  3. Gradient Boosting")
    print()
    
    for model_type in models_to_train:
        print(f"\n{'=' * 60}")
        print(f"Training: {model_type.upper()}")
        print(f"{'=' * 60}")
        try:
            trainer.train(model_type=model_type)
        except Exception as e:
            print(f"❌ Error training {model_type}: {str(e)}")
            continue
    
    print("\n" + "=" * 60)
    print("✅ Training ทุกโมเดลเสร็จสิ้น!")
    print("=" * 60)
    print("\n💡 ขั้นตอนต่อไป:")
    print("  1. ตรวจสอบผลลัพธ์ในไฟล์ .png")
    print("  2. เลือกโมเดลที่ดีที่สุด")
    print("  3. นำโมเดลไปใช้กับ EA ใน MetaTrader 5")

if __name__ == '__main__':
    main()
