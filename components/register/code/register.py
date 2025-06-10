import argparse
import os
from azure.ai.ml import MLClient
from azure.ai.ml.entities import Model
from azure.identity import ClientSecretCredential
import json

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, required=True)
    parser.add_argument("--model_name", type=str, default="boston-housing-model")
    args = parser.parse_args()

    with open(".azureml/config.json") as f:
        cfg = json.load(f)

    cred = ClientSecretCredential(
        client_id=cfg["credential"]["client_id"],
        tenant_id=cfg["credential"]["tenant_id"],
        client_secret=cfg["credential"]["client_secret"]
    )

    ml_client = MLClient(
        credential=cred,
        subscription_id=cfg["subscription_id"],
        resource_group=cfg["resource_group"],
        workspace_name=cfg["workspace_name"]
    )

    model = Model(
        path=args.model_path,
        name=args.model_name,
        type="custom_model"
    )
    ml_client.models.create_or_update(model)

if __name__ == "__main__":
    main()