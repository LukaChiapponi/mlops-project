import os
import argparse
import logging
from glob import glob

import numpy as np
import pandas as pd
from scipy.stats import skew
from sklearn.preprocessing import StandardScaler
import joblib

def main():
    """Main function of the script."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=str, required=True)
    parser.add_argument('--data_cleaned', type=str, required=True)
    args = parser.parse_args()

    print(" ".join(f"{k}={v}" for k, v in vars(args).items()))

    # Load train data
    df_train = pd.read_csv(args.data)

    # Drop specified columns
    df_train.drop(['B', 'RAD'], axis=1, inplace=True)

    # Remove duplicates
    df_train.drop_duplicates(inplace=True)

    # Skewness correction
    num_cols = df_train.select_dtypes(include=['float64', 'int64']).columns
    skewed = df_train[num_cols].apply(lambda x: skew(x.dropna().astype(float)))
    skewed = skewed[skewed > 0.75].index
    df_train[skewed] = np.log1p(df_train[skewed])

    # Standardize
    scaler = StandardScaler()
    df_train[num_cols] = scaler.fit_transform(df_train[num_cols])

    # Save outputs
    os.makedirs(args.data_cleaned, exist_ok=True)
    df_train.to_csv(os.path.join(args.data_cleaned, "train_cleaned.csv"), index=False)
    joblib.dump(scaler, os.path.join(args.data_cleaned, "scaler.pkl"))

if __name__ == "__main__":
    main()
