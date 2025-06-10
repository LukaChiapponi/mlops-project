import argparse
import os
from azure.ai.ml import MLClient
from azure.ai.ml.entities import Model
from azure.identity import DefaultAzureCredential

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, required=True)
    parser.add_argument("--model_name", type=str, default="boston-housing-model")
    args = parser.parse_args()

    ml_client = MLClient(
        DefaultAzureCredential(),
        os.environ["AZURE_SUBSCRIPTION_ID"],
        os.environ["AZURE_RESOURCE_GROUP"],
        os.environ["AZURE_WORKSPACE_NAME"]
    )

    model = Model(
        path=args.model_path,
        name=args.model_name,
        type="custom_model"
    )
    ml_client.models.create_or_update(model)

if __name__ == "__main__":
    main()