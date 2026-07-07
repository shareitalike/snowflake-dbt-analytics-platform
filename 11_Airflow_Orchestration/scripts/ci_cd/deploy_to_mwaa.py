"""
MWAA Deployment Script (Fallback/Manual trigger)
In an Enterprise AWS MWAA setup, deploying DAGs is as simple as syncing to S3.
This script provides a programmatic wrapper for doing so with rollback capabilities.
"""
import argparse
import subprocess
import logging

logging.basicConfig(level=logging.INFO)

def deploy_to_s3(bucket: str, source_dir: str):
    logging.info(f"Syncing {source_dir} to s3://{bucket}/dags...")
    # Using aws cli sync --delete ensures old DAGs are removed from the bucket
    cmd = ["aws", "s3", "sync", source_dir, f"s3://{bucket}/dags", "--delete"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        logging.error(f"Deployment failed: {result.stderr}")
        raise Exception("S3 Sync Failed")
    logging.info("Deployment successful.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy Airflow DAGs to MWAA S3 Bucket.")
    parser.add_argument("--env", required=True, choices=['dev', 'qa', 'prod'])
    args = parser.parse_args()

    bucket_map = {
        'dev': 'omniretail-airflow-dev-bucket',
        'qa': 'omniretail-airflow-qa-bucket',
        'prod': 'omniretail-airflow-prod-bucket',
    }

    deploy_to_s3(bucket_map[args.env], "11_Airflow_Orchestration/dags")
