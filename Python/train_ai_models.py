#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
╔════════════════════════════════════════════════════════════╗
║  🤖 AI TRADING MODEL TRAINER                              ║
║  ระบบ Training ML Models สำหรับ Forex Trading            ║
╚════════════════════════════════════════════════════════════╝

สคริปต์นี้จะ train หลายโมเดล:
1. Neural Network (MLP)
2. Random Forest
3. Gradient Boosting (XGBoost)
4. LSTM (Deep Learning)
5. Ensemble Model

Author: EA-MQL5 AI Trading
Version: 2.0
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings
import os
import joblib

warnings.filterwarnings('ignore')

# Machine Learning Libraries
from sklearn.model_selection import train_test_split, TimeSeriesSplit, cross_val_score
from sklearn.preprocessing import StandardScaler, RobustScaler
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                             f1_score, roc_auc_score, confusion_matrix,
                             classification_report)

# Models
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, VotingClassifier
from xgboost import XGBClassifier
from lightgbm import LGBMClassifier

# Deep Learning (Optional)
try:
    from tensorflow import keras
    from tensorflow.keras.models import Sequential
    from tensorflow.keras.layers import Dense, LSTM, Dropout, BatchNormalization
    from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
    KERAS_AVAILABLE = True
except ImportError:
    print("⚠️ TensorFlow/Keras ไม่พร้อมใช้งาน - ข้าม LSTM model")
    KERAS_AVAILABLE = False

class AITradingTrainer:
    """
    คลาสสำหรับ train AI trading models
    """
    
    def __init__(self, data_file='ai_training_data.csv'):
        """
        Initialize Trainer
        
        Args:
            data_file: ไฟล์ CSV ที่ได้จาก AI_DataCollector.mq5
        """
        self.data_file = data_file
        self.df = None
        self.X_train = None
        self.X_test = None
        self.y_train = None
        self.y_test = None
        self.scaler = None
        self.feature_names = None
        self.models = {}
        self.results = {}
        
        # สร้างโฟลเดอร์สำหรับเก็บผลลัพธ์
        os.makedirs('models', exist_ok=True)
        os.makedirs('plots', exist_ok=True)
        os.makedirs('reports', exist_ok=True)
        
    def load_data(self):
        """โหลดข้อมูลจากไฟล์ CSV"""
        print("\n" + "="*60)
        print("📂 กำลังโหลดข้อมูล...")
        print("="*60)
        
        self.df = pd.read_csv(self.data_file)
        print(f"✅ โหลดข้อมูลสำเร็จ: {len(self.df):,} rows")
        print(f"📊 Columns: {len(self.df.columns)}")
        print(f"📅 Date range: {self.df['Time'].iloc[0]} to {self.df['Time'].iloc[-1]}")
        
        # ตรวจสอบ missing values
        missing = self.df.isnull().sum()
        if missing.sum() > 0:
            print(f"\n⚠️ พบ Missing Values:")
            print(missing[missing > 0])
            self.df = self.df.dropna()
            print(f"✅ ลบ rows ที่มี missing values แล้ว: {len(self.df):,} rows เหลือ")
        
        return self.df
    
    def prepare_data(self, target_col='Future_Direction', test_size=0.2):
        """
        เตรียมข้อมูลสำหรับการ train
        
        Args:
            target_col: คอลัมน์ target
            test_size: สัดส่วนของ test set
        """
        print("\n" + "="*60)
        print("🔧 กำลังเตรียมข้อมูล...")
        print("="*60)
        
        # กำหนด feature columns (ยกเว้น time, price, และ target columns)
        exclude_cols = ['Time', 'Open', 'High', 'Low', 'Close', 'Volume',
                       'Future_Close', 'Future_Change', 'Future_Change_Pct',
                       'Future_Direction', 'Max_Up_Move', 'Max_Down_Move']
        
        feature_cols = [col for col in self.df.columns if col not in exclude_cols]
        self.feature_names = feature_cols
        
        print(f"📊 Features: {len(feature_cols)}")
        print(f"🎯 Target: {target_col}")
        
        # แยก features และ target
        X = self.df[feature_cols].values
        y = self.df[target_col].values
        
        # ตรวจสอบ class distribution
        unique, counts = np.unique(y, return_counts=True)
        print(f"\n📈 Target Distribution:")
        for u, c in zip(unique, counts):
            print(f"  Class {u}: {c:,} ({c/len(y)*100:.1f}%)")
        
        # แบ่งข้อมูล (Time-based split สำหรับ time series)
        split_idx = int(len(X) * (1 - test_size))
        X_train = X[:split_idx]
        X_test = X[split_idx:]
        y_train = y[:split_idx]
        y_test = y[split_idx:]
        
        print(f"\n✂️ Data Split:")
        print(f"  Training: {len(X_train):,} samples")
        print(f"  Testing: {len(X_test):,} samples")
        
        # Normalize features
        print(f"\n🔄 Normalizing features...")
        self.scaler = RobustScaler()  # ใช้ RobustScaler เพราะทนต่อ outliers
        X_train = self.scaler.fit_transform(X_train)
        X_test = self.scaler.transform(X_test)
        
        self.X_train = X_train
        self.X_test = X_test
        self.y_train = y_train
        self.y_test = y_test
        
        print("✅ เตรียมข้อมูลเสร็จสิ้น")
        
        return X_train, X_test, y_train, y_test
    
    def train_neural_network(self):
        """Train Neural Network (MLP)"""
        print("\n" + "="*60)
        print("🧠 Training Neural Network (MLP)...")
        print("="*60)
        
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
            validation_fraction=0.1,
            n_iter_no_change=20
        )
        
        model.fit(self.X_train, self.y_train)
        
        self.models['neural_network'] = model
        self.evaluate_model('neural_network', model)
        
        return model
    
    def train_random_forest(self):
        """Train Random Forest"""
        print("\n" + "="*60)
        print("🌲 Training Random Forest...")
        print("="*60)
        
        model = RandomForestClassifier(
            n_estimators=300,
            max_depth=20,
            min_samples_split=5,
            min_samples_leaf=2,
            max_features='sqrt',
            random_state=42,
            n_jobs=-1,
            verbose=1
        )
        
        model.fit(self.X_train, self.y_train)
        
        self.models['random_forest'] = model
        self.evaluate_model('random_forest', model)
        self.plot_feature_importance('random_forest', model)
        
        return model
    
    def train_xgboost(self):
        """Train XGBoost"""
        print("\n" + "="*60)
        print("🚀 Training XGBoost...")
        print("="*60)
        
        model = XGBClassifier(
            n_estimators=300,
            max_depth=6,
            learning_rate=0.1,
            subsample=0.8,
            colsample_bytree=0.8,
            random_state=42,
            n_jobs=-1,
            verbosity=1
        )
        
        model.fit(self.X_train, self.y_train,
                 eval_set=[(self.X_test, self.y_test)],
                 verbose=False)
        
        self.models['xgboost'] = model
        self.evaluate_model('xgboost', model)
        self.plot_feature_importance('xgboost', model)
        
        return model
    
    def train_lightgbm(self):
        """Train LightGBM"""
        print("\n" + "="*60)
        print("💡 Training LightGBM...")
        print("="*60)
        
        model = LGBMClassifier(
            n_estimators=300,
            max_depth=8,
            learning_rate=0.1,
            subsample=0.8,
            colsample_bytree=0.8,
            random_state=42,
            n_jobs=-1,
            verbose=1
        )
        
        model.fit(self.X_train, self.y_train,
                 eval_set=[(self.X_test, self.y_test)],
                 verbose=False)
        
        self.models['lightgbm'] = model
        self.evaluate_model('lightgbm', model)
        self.plot_feature_importance('lightgbm', model)
        
        return model
    
    def train_ensemble(self):
        """Train Ensemble Model"""
        print("\n" + "="*60)
        print("🎯 Training Ensemble Model...")
        print("="*60)
        
        # ใช้โมเดลที่ train แล้ว
        estimators = []
        for name, model in self.models.items():
            if name != 'ensemble':
                estimators.append((name, model))
        
        if len(estimators) == 0:
            print("⚠️ ไม่มีโมเดลสำหรับสร้าง ensemble")
            return None
        
        model = VotingClassifier(
            estimators=estimators,
            voting='soft',
            n_jobs=-1
        )
        
        model.fit(self.X_train, self.y_train)
        
        self.models['ensemble'] = model
        self.evaluate_model('ensemble', model)
        
        return model
    
    def evaluate_model(self, name, model):
        """
        ประเมินผลโมเดล
        
        Args:
            name: ชื่อโมเดล
            model: โมเดลที่จะประเมิน
        """
        # Predictions
        y_pred_train = model.predict(self.X_train)
        y_pred_test = model.predict(self.X_test)
        
        # Probabilities (สำหรับ ROC-AUC)
        if hasattr(model, 'predict_proba'):
            y_prob_test = model.predict_proba(self.X_test)[:, 1]
        else:
            y_prob_test = y_pred_test
        
        # Metrics
        train_acc = accuracy_score(self.y_train, y_pred_train)
        test_acc = accuracy_score(self.y_test, y_pred_test)
        precision = precision_score(self.y_test, y_pred_test, zero_division=0)
        recall = recall_score(self.y_test, y_pred_test, zero_division=0)
        f1 = f1_score(self.y_test, y_pred_test, zero_division=0)
        
        try:
            roc_auc = roc_auc_score(self.y_test, y_prob_test)
        except:
            roc_auc = 0
        
        # เก็บผลลัพธ์
        self.results[name] = {
            'train_accuracy': train_acc,
            'test_accuracy': test_acc,
            'precision': precision,
            'recall': recall,
            'f1_score': f1,
            'roc_auc': roc_auc
        }
        
        # แสดงผล
        print(f"\n📊 {name.upper()} Results:")
        print(f"  Train Accuracy: {train_acc:.4f}")
        print(f"  Test Accuracy:  {test_acc:.4f}")
        print(f"  Precision:      {precision:.4f}")
        print(f"  Recall:         {recall:.4f}")
        print(f"  F1-Score:       {f1:.4f}")
        print(f"  ROC-AUC:        {roc_auc:.4f}")
        
        # Confusion Matrix
        cm = confusion_matrix(self.y_test, y_pred_test)
        self.plot_confusion_matrix(name, cm)
        
        # Classification Report
        print(f"\n{classification_report(self.y_test, y_pred_test, target_names=['Down', 'Up'])}")
    
    def plot_feature_importance(self, name, model):
        """Plot Feature Importance"""
        if hasattr(model, 'feature_importances_'):
            importances = model.feature_importances_
            indices = np.argsort(importances)[::-1][:20]  # Top 20
            
            plt.figure(figsize=(12, 8))
            plt.title(f'Top 20 Feature Importance - {name.upper()}')
            plt.barh(range(len(indices)), importances[indices])
            plt.yticks(range(len(indices)), [self.feature_names[i] for i in indices])
            plt.xlabel('Importance')
            plt.tight_layout()
            plt.savefig(f'plots/feature_importance_{name}.png', dpi=300)
            print(f"💾 บันทึก feature importance: plots/feature_importance_{name}.png")
            plt.close()
    
    def plot_confusion_matrix(self, name, cm):
        """Plot Confusion Matrix"""
        plt.figure(figsize=(8, 6))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                   xticklabels=['Down', 'Up'],
                   yticklabels=['Down', 'Up'])
        plt.title(f'Confusion Matrix - {name.upper()}')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.tight_layout()
        plt.savefig(f'plots/confusion_matrix_{name}.png', dpi=300)
        print(f"💾 บันทึก confusion matrix: plots/confusion_matrix_{name}.png")
        plt.close()
    
    def save_models(self):
        """บันทึกโมเดลทั้งหมด"""
        print("\n" + "="*60)
        print("💾 กำลังบันทึกโมเดล...")
        print("="*60)
        
        # บันทึก scaler
        joblib.dump(self.scaler, 'models/scaler.pkl')
        print(f"✅ บันทึก scaler: models/scaler.pkl")
        
        # บันทึกแต่ละโมเดล
        for name, model in self.models.items():
            filename = f'models/{name}_model.pkl'
            joblib.dump(model, filename)
            print(f"✅ บันทึก {name}: {filename}")
        
        # บันทึก feature names
        joblib.dump(self.feature_names, 'models/feature_names.pkl')
        print(f"✅ บันทึก feature names: models/feature_names.pkl")
    
    def generate_report(self):
        """สร้างรายงานสรุป"""
        print("\n" + "="*60)
        print("📝 กำลังสร้างรายงาน...")
        print("="*60)
        
        # สร้าง DataFrame จากผลลัพธ์
        df_results = pd.DataFrame(self.results).T
        df_results = df_results.round(4)
        
        # บันทึกเป็น CSV
        df_results.to_csv('reports/model_comparison.csv')
        print(f"✅ บันทึกรายงาน: reports/model_comparison.csv")
        
        # แสดงตาราง
        print("\n📊 MODEL COMPARISON:")
        print(df_results.to_string())
        
        # หาโมเดลที่ดีที่สุด
        best_model = df_results['test_accuracy'].idxmax()
        best_acc = df_results.loc[best_model, 'test_accuracy']
        
        print(f"\n🏆 Best Model: {best_model.upper()}")
        print(f"   Test Accuracy: {best_acc:.4f}")
        
        # Plot comparison
        self.plot_model_comparison(df_results)
        
        return df_results
    
    def plot_model_comparison(self, df_results):
        """Plot Model Comparison"""
        metrics = ['test_accuracy', 'precision', 'recall', 'f1_score', 'roc_auc']
        
        fig, axes = plt.subplots(2, 3, figsize=(15, 10))
        axes = axes.ravel()
        
        for idx, metric in enumerate(metrics):
            df_results[metric].plot(kind='barh', ax=axes[idx])
            axes[idx].set_title(metric.replace('_', ' ').title())
            axes[idx].set_xlabel('Score')
            
        # ซ่อน subplot ที่เหลือ
        axes[5].axis('off')
        
        plt.tight_layout()
        plt.savefig('plots/model_comparison.png', dpi=300)
        print(f"💾 บันทึก model comparison: plots/model_comparison.png")
        plt.close()
    
    def train_all(self):
        """Train โมเดลทั้งหมด"""
        print("\n" + "╔" + "="*58 + "╗")
        print("║" + " "*15 + "🤖 AI MODEL TRAINING" + " "*23 + "║")
        print("╚" + "="*58 + "╝")
        
        # 1. โหลดข้อมูล
        self.load_data()
        
        # 2. เตรียมข้อมูล
        self.prepare_data()
        
        # 3. Train แต่ละโมเดล
        self.train_neural_network()
        self.train_random_forest()
        self.train_xgboost()
        self.train_lightgbm()
        
        # 4. Train Ensemble
        self.train_ensemble()
        
        # 5. บันทึกโมเดล
        self.save_models()
        
        # 6. สร้างรายงาน
        self.generate_report()
        
        print("\n" + "╔" + "="*58 + "╗")
        print("║" + " "*15 + "✅ TRAINING COMPLETED!" + " "*20 + "║")
        print("╚" + "="*58 + "╝")
        print("\n💡 ขั้นตอนต่อไป:")
        print("  1. ตรวจสอบรายงานใน reports/model_comparison.csv")
        print("  2. ดูกราฟใน plots/")
        print("  3. เลือกโมเดลที่ดีที่สุดจาก models/")
        print("  4. นำโมเดลไปใช้กับ EA ใน MetaTrader 5")

def main():
    """Main function"""
    import sys
    
    # ตรวจสอบ arguments
    data_file = 'ai_training_data.csv'
    if len(sys.argv) > 1:
        data_file = sys.argv[1]
    
    # สร้าง trainer
    trainer = AITradingTrainer(data_file)
    
    # Train ทุกโมเดล
    trainer.train_all()

if __name__ == '__main__':
    main()
