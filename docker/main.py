from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
import logging
import os
import tensorflow as tf
from tensorflow.keras.models import load_model

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Housing Price Prediction API",
    description="API for predicting housing prices based on property features",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class HousePredictionRequest(BaseModel):
    CRIM: float     # per capita crime rate by town
    ZN: float       # proportion of residential land zoned for lots over 25,000 sq.ft.
    INDUS: float    # proportion of non-retail business acres per town
    CHAS: int       # Charles River dummy variable (= 1 if tract bounds river; 0 otherwise)
    NOX: float      # nitric oxides concentration (parts per 10 million)
    RM: float       # average number of rooms per dwelling
    AGE: float      # proportion of owner-occupied units built prior to 1940
    DIS: float      # weighted distances to five Boston employment centres
    TAX: float      # full-value property-tax rate per $10,000
    PTRATIO: float  # pupil-teacher ratio by town
    LSTAT: float    # % lower status of the population

class PredictionResponse(BaseModel):
    predicted_price: float
    formatted_price: str
    features_used: dict

model = None

def load_model_func():
    """Load the trained TensorFlow model"""
    global model
    try:
        model_path = os.getenv("MODEL_PATH", "trained_model.h5")
        model = load_model(model_path)
        logger.info(f"TensorFlow model loaded successfully from {model_path}")
        logger.info(f"Model input shape: {model.input_shape}")
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        logger.info("Creating dummy TensorFlow model for development...")
        model = tf.keras.Sequential([
            tf.keras.layers.Dense(64, activation='relu', input_shape=(11,)),
            tf.keras.layers.Dense(32, activation='relu'),
            tf.keras.layers.Dense(1)
        ])
        model.compile(optimizer='adam', loss='mse')
        
        X_dummy = np.random.rand(100, 11)
        y_dummy = np.random.rand(100, 1) * 50
        model.fit(X_dummy, y_dummy, epochs=1, verbose=0)
        logger.info("Dummy TensorFlow model created with 11 features")

@app.on_event("startup")
async def startup_event():
    """Load model on startup"""
    load_model_func()

@app.get("/")
async def root():
    return {"message": "Boston Housing Price Prediction API", "status": "running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "model_type": "TensorFlow/Keras"
    }

@app.post("/predict")
async def predict_price(request: HousePredictionRequest):
    try:
        if model is None:
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        features = np.array([[
            request.CRIM, request.ZN, request.INDUS, request.CHAS, request.NOX,
            request.RM, request.AGE, request.DIS, request.TAX, request.PTRATIO, request.LSTAT
        ]])
        
        logger.info(f"Input features shape: {features.shape}")
        
        prediction = model.predict(features, verbose=0)[0][0]
        
        return {
            "predicted_price": float(prediction),
            "formatted_price": f"${prediction:.2f}K",
            "features_used": {
                "CRIM": request.CRIM,
                "ZN": request.ZN,
                "INDUS": request.INDUS,
                "CHAS": request.CHAS,
                "NOX": request.NOX,
                "RM": request.RM,
                "AGE": request.AGE,
                "DIS": request.DIS,
                "TAX": request.TAX,
                "PTRATIO": request.PTRATIO,
                "LSTAT": request.LSTAT
            }
        }
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/model-info")
async def get_model_info():
    """Get information about the loaded model"""
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
   
    return {
        "model_type": "TensorFlow/Keras",
        "input_shape": str(model.input_shape),
        "features_expected": 11,
        "feature_names": [
            "CRIM", "ZN", "INDUS", "CHAS", "NOX",
            "RM", "AGE", "DIS", "TAX", "PTRATIO", "LSTAT"
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)