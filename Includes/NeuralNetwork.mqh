//+------------------------------------------------------------------+
//|                                              NeuralNetwork.mqh   |
//|                                       Neural Network Library     |
//|                            สำหรับสร้าง Neural Network ใน MQL5    |
//+------------------------------------------------------------------+
#property copyright "EA-MQL5 AI Trading"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Activation Functions                                              |
//+------------------------------------------------------------------+
class ActivationFunction
{
public:
   // Sigmoid
   static double Sigmoid(double x)
   {
      return 1.0 / (1.0 + MathExp(-x));
   }
   
   static double SigmoidDerivative(double x)
   {
      double sig = Sigmoid(x);
      return sig * (1.0 - sig);
   }
   
   // Tanh
   static double Tanh(double x)
   {
      return MathTanh(x);
   }
   
   static double TanhDerivative(double x)
   {
      double t = Tanh(x);
      return 1.0 - t * t;
   }
   
   // ReLU
   static double ReLU(double x)
   {
      return (x > 0) ? x : 0;
   }
   
   static double ReLUDerivative(double x)
   {
      return (x > 0) ? 1.0 : 0.0;
   }
   
   // Leaky ReLU
   static double LeakyReLU(double x, double alpha = 0.01)
   {
      return (x > 0) ? x : alpha * x;
   }
   
   static double LeakyReLUDerivative(double x, double alpha = 0.01)
   {
      return (x > 0) ? 1.0 : alpha;
   }
};

//+------------------------------------------------------------------+
//| Matrix Helper Class                                               |
//+------------------------------------------------------------------+
class MatrixHelper
{
public:
   // คูณ Matrix
   static void MatrixMultiply(const double &A[], const double &B[], 
                             double &C[], int rowsA, int colsA, int colsB)
   {
      ArrayResize(C, rowsA * colsB);
      ArrayInitialize(C, 0);
      
      for(int i = 0; i < rowsA; i++)
      {
         for(int j = 0; j < colsB; j++)
         {
            for(int k = 0; k < colsA; k++)
            {
               C[i * colsB + j] += A[i * colsA + k] * B[k * colsB + j];
            }
         }
      }
   }
   
   // Transpose Matrix
   static void MatrixTranspose(const double &A[], double &AT[], int rows, int cols)
   {
      ArrayResize(AT, rows * cols);
      for(int i = 0; i < rows; i++)
      {
         for(int j = 0; j < cols; j++)
         {
            AT[j * rows + i] = A[i * cols + j];
         }
      }
   }
};

//+------------------------------------------------------------------+
//| Neural Network Layer                                              |
//+------------------------------------------------------------------+
class NeuralLayer
{
private:
   int m_inputSize;
   int m_outputSize;
   double m_weights[];
   double m_biases[];
   double m_outputs[];
   double m_inputs[];
   double m_gradients[];
   string m_activation;
   
public:
   NeuralLayer() {}
   
   // Constructor
   NeuralLayer(int inputSize, int outputSize, string activation = "sigmoid")
   {
      m_inputSize = inputSize;
      m_outputSize = outputSize;
      m_activation = activation;
      
      // สร้าง weights และ biases
      ArrayResize(m_weights, m_inputSize * m_outputSize);
      ArrayResize(m_biases, m_outputSize);
      ArrayResize(m_outputs, m_outputSize);
      ArrayResize(m_gradients, m_outputSize);
      
      // Initialize weights (Xavier initialization)
      double limit = MathSqrt(6.0 / (m_inputSize + m_outputSize));
      for(int i = 0; i < ArraySize(m_weights); i++)
      {
         m_weights[i] = ((MathRand() / 32767.0) * 2.0 - 1.0) * limit;
      }
      
      // Initialize biases
      ArrayInitialize(m_biases, 0);
   }
   
   // Forward pass
   void Forward(const double &inputs[])
   {
      ArrayResize(m_inputs, ArraySize(inputs));
      ArrayCopy(m_inputs, inputs);
      
      // คำนวณ output แต่ละ neuron
      for(int i = 0; i < m_outputSize; i++)
      {
         double sum = m_biases[i];
         for(int j = 0; j < m_inputSize; j++)
         {
            sum += inputs[j] * m_weights[j * m_outputSize + i];
         }
         
         // Apply activation function
         if(m_activation == "sigmoid")
            m_outputs[i] = ActivationFunction::Sigmoid(sum);
         else if(m_activation == "tanh")
            m_outputs[i] = ActivationFunction::Tanh(sum);
         else if(m_activation == "relu")
            m_outputs[i] = ActivationFunction::ReLU(sum);
         else if(m_activation == "leaky_relu")
            m_outputs[i] = ActivationFunction::LeakyReLU(sum);
         else // linear
            m_outputs[i] = sum;
      }
   }
   
   // Get outputs
   void GetOutputs(double &outputs[])
   {
      ArrayResize(outputs, m_outputSize);
      ArrayCopy(outputs, m_outputs);
   }
   
   // Update weights (gradient descent)
   void UpdateWeights(const double &gradients[], double learningRate)
   {
      ArrayCopy(m_gradients, gradients);
      
      // Update weights
      for(int i = 0; i < m_outputSize; i++)
      {
         // Update bias
         m_biases[i] -= learningRate * gradients[i];
         
         // Update weights
         for(int j = 0; j < m_inputSize; j++)
         {
            m_weights[j * m_outputSize + i] -= learningRate * gradients[i] * m_inputs[j];
         }
      }
   }
   
   // Get weights
   void GetWeights(double &weights[])
   {
      ArrayResize(weights, ArraySize(m_weights));
      ArrayCopy(weights, m_weights);
   }
   
   // Set weights
   void SetWeights(const double &weights[])
   {
      if(ArraySize(weights) == ArraySize(m_weights))
         ArrayCopy(m_weights, weights);
   }
   
   // Get biases
   void GetBiases(double &biases[])
   {
      ArrayResize(biases, ArraySize(m_biases));
      ArrayCopy(biases, m_biases);
   }
   
   // Set biases
   void SetBiases(const double &biases[])
   {
      if(ArraySize(biases) == ArraySize(m_biases))
         ArrayCopy(biases, biases);
   }
   
   int GetInputSize() { return m_inputSize; }
   int GetOutputSize() { return m_outputSize; }
};

//+------------------------------------------------------------------+
//| Complete Neural Network                                           |
//+------------------------------------------------------------------+
class NeuralNetwork
{
private:
   NeuralLayer* m_layers[];
   int m_numLayers;
   double m_learningRate;
   
public:
   NeuralNetwork() 
   {
      m_numLayers = 0;
      m_learningRate = 0.01;
   }
   
   ~NeuralNetwork()
   {
      for(int i = 0; i < m_numLayers; i++)
      {
         if(CheckPointer(m_layers[i]) == POINTER_DYNAMIC)
            delete m_layers[i];
      }
   }
   
   // เพิ่ม layer
   void AddLayer(int inputSize, int outputSize, string activation = "sigmoid")
   {
      m_numLayers++;
      ArrayResize(m_layers, m_numLayers);
      m_layers[m_numLayers - 1] = new NeuralLayer(inputSize, outputSize, activation);
   }
   
   // Forward propagation
   void Predict(const double &inputs[], double &outputs[])
   {
      if(m_numLayers == 0)
      {
         Print("Error: No layers in network");
         return;
      }
      
      double currentInputs[];
      double currentOutputs[];
      
      ArrayResize(currentInputs, ArraySize(inputs));
      ArrayCopy(currentInputs, inputs);
      
      // ผ่านแต่ละ layer
      for(int i = 0; i < m_numLayers; i++)
      {
         m_layers[i].Forward(currentInputs);
         m_layers[i].GetOutputs(currentOutputs);
         ArrayCopy(currentInputs, currentOutputs);
      }
      
      // Output สุดท้าย
      ArrayResize(outputs, ArraySize(currentOutputs));
      ArrayCopy(outputs, currentOutputs);
   }
   
   // Train with single sample (online learning)
   double Train(const double &inputs[], const double &targets[], double learningRate = -1)
   {
      if(learningRate > 0)
         m_learningRate = learningRate;
      
      // Forward pass
      double outputs[];
      Predict(inputs, outputs);
      
      // คำนวณ error
      double error = 0;
      double outputGradients[];
      ArrayResize(outputGradients, ArraySize(outputs));
      
      for(int i = 0; i < ArraySize(outputs); i++)
      {
         double diff = targets[i] - outputs[i];
         error += diff * diff;
         outputGradients[i] = -2.0 * diff; // MSE derivative
      }
      
      // Backward pass (simplified - just update last layer)
      m_layers[m_numLayers - 1].UpdateWeights(outputGradients, m_learningRate);
      
      return MathSqrt(error / ArraySize(outputs)); // RMSE
   }
   
   // บันทึก network
   bool SaveToFile(string filename)
   {
      int handle = FileOpen(filename, FILE_WRITE|FILE_BIN);
      if(handle == INVALID_HANDLE)
      {
         Print("Error: Cannot create file ", filename);
         return false;
      }
      
      // บันทึกจำนวน layers
      FileWriteInteger(handle, m_numLayers);
      FileWriteDouble(handle, m_learningRate);
      
      // บันทึกแต่ละ layer
      for(int i = 0; i < m_numLayers; i++)
      {
         FileWriteInteger(handle, m_layers[i].GetInputSize());
         FileWriteInteger(handle, m_layers[i].GetOutputSize());
         
         double weights[], biases[];
         m_layers[i].GetWeights(weights);
         m_layers[i].GetBiases(biases);
         
         // บันทึก weights
         FileWriteInteger(handle, ArraySize(weights));
         for(int j = 0; j < ArraySize(weights); j++)
            FileWriteDouble(handle, weights[j]);
         
         // บันทึก biases
         FileWriteInteger(handle, ArraySize(biases));
         for(int j = 0; j < ArraySize(biases); j++)
            FileWriteDouble(handle, biases[j]);
      }
      
      FileClose(handle);
      Print("Network saved to: ", filename);
      return true;
   }
   
   // โหลด network
   bool LoadFromFile(string filename)
   {
      int handle = FileOpen(filename, FILE_READ|FILE_BIN);
      if(handle == INVALID_HANDLE)
      {
         Print("Error: Cannot open file ", filename);
         return false;
      }
      
      // ลบ layers เก่า
      for(int i = 0; i < m_numLayers; i++)
      {
         if(CheckPointer(m_layers[i]) == POINTER_DYNAMIC)
            delete m_layers[i];
      }
      
      // โหลดจำนวน layers
      m_numLayers = FileReadInteger(handle);
      m_learningRate = FileReadDouble(handle);
      ArrayResize(m_layers, m_numLayers);
      
      // โหลดแต่ละ layer
      for(int i = 0; i < m_numLayers; i++)
      {
         int inputSize = FileReadInteger(handle);
         int outputSize = FileReadInteger(handle);
         
         m_layers[i] = new NeuralLayer(inputSize, outputSize);
         
         // โหลด weights
         int weightsSize = FileReadInteger(handle);
         double weights[];
         ArrayResize(weights, weightsSize);
         for(int j = 0; j < weightsSize; j++)
            weights[j] = FileReadDouble(handle);
         m_layers[i].SetWeights(weights);
         
         // โหลด biases
         int biasesSize = FileReadInteger(handle);
         double biases[];
         ArrayResize(biases, biasesSize);
         for(int j = 0; j < biasesSize; j++)
            biases[j] = FileReadDouble(handle);
         m_layers[i].SetBiases(biases);
      }
      
      FileClose(handle);
      Print("Network loaded from: ", filename);
      return true;
   }
   
   void SetLearningRate(double rate) { m_learningRate = rate; }
   double GetLearningRate() { return m_learningRate; }
   int GetNumLayers() { return m_numLayers; }
};
//+------------------------------------------------------------------+
