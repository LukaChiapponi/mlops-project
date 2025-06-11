import pandas as pd
import numpy as np
import argparse
import os
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping

def augment_data_with_gaussian_noise(X, y, noise_level=0.01):
    # Add Gaussian noise to the features
    X_noisy = X + np.random.normal(0, noise_level * X.std(), X.shape)
    # Add Gaussian noise to the target
    y_noisy = y + np.random.normal(0, noise_level * y.std(), y.shape)
    # Concatenate the original and noisy data
    X_augmented = pd.concat([X, pd.DataFrame(X_noisy, columns=X.columns)], ignore_index=True)
    y_augmented = pd.concat([y, pd.Series(y_noisy)], ignore_index=True)
    return X_augmented, y_augmented

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Train AI model')
    parser.add_argument('--training_data', type=str, required=True, help='Path to training data CSV')
    parser.add_argument('--epochs', type=int, required=True, help='Number of training epochs')
    parser.add_argument('--noise_level', type=float, default=0.01, help='Noise level for data augmentation')
    parser.add_argument('--output_folder', type=str, required=True, help='Output folder for model')
    
    args = parser.parse_args()
    
    # Load data from the provided path

    csv_path = os.path.join(args.training_data, "train_cleaned.csv")
    df = pd.read_csv(csv_path)
    X = df.drop(['MEDV'], axis=1)
    y = df['MEDV']
    
    print(f"Original dataset size: {X.shape[0]}")

    # Apply data augmentation with the specified noise level
    X, y = augment_data_with_gaussian_noise(X, y, noise_level=args.noise_level)

    print(f"Augmented dataset size: {X.shape[0]}")
    
    # Build model
    rate = 0.1
    model = Sequential([
        Dense(256, activation='relu', input_shape=(X.shape[1],)),
        Dropout(rate),
        Dense(128, activation='relu'),
        Dropout(rate),
        Dense(64, activation='relu'),
        Dense(1, activation='relu'),
        Dense(1)
    ])

    model.compile(optimizer='adam', loss='mse', metrics=['mae'])
    early_stopping = EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True)
    
    # Use the epochs parameter from Azure ML
    fit1 = model.fit(X, y, epochs=args.epochs, validation_split=0.2, batch_size=16, callbacks=[early_stopping])
    
    # Save model to output folder
    model.save(os.path.join(args.output_folder, "trained_model.h5"))
    # Save scaler to output folder
    import joblib
    scaler_path = os.path.join(args.output_folder, "scaler.pkl")
    joblib.dump(args.output_folder, scaler_path)
    
if __name__ == "__main__":
    main()