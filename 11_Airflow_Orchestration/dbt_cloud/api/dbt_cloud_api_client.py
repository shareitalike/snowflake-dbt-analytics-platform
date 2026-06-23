"""
Enterprise dbt Cloud API Client
Extends standard Airflow dbt Cloud integration to pull specific Artifacts 
(run_results.json, manifest.json) for internal Data Quality monitoring and metadata capture.
"""
import logging
import json
from airflow.providers.dbt.cloud.hooks.dbt import DbtCloudHook

class EnterpriseDbtCloudClient:
    """
    Wrapper around DbtCloudHook to perform advanced Administrative API tasks.
    """
    def __init__(self, dbt_cloud_conn_id: str = 'dbt_cloud_default'):
        self.hook = DbtCloudHook(dbt_cloud_conn_id=dbt_cloud_conn_id)
        self.account_id = self.hook.get_connection(dbt_cloud_conn_id).extra_dejson.get('account_id')

    def cancel_stuck_job(self, run_id: int):
        """
        Force cancels a dbt Cloud run if it exceeds SLA thresholds.
        """
        logging.info(f"Issuing cancellation request for dbt Cloud Run ID: {run_id}")
        # DbtCloudHook handles the REST API call and auth headers automatically
        self.hook.cancel_job_run(account_id=self.account_id, run_id=run_id)
        logging.info(f"Run {run_id} successfully cancelled.")

    def fetch_run_results_artifact(self, run_id: int) -> dict:
        """
        Pulls the run_results.json artifact after a job completes to parse 
        for specific test failures or row counts to log to our custom monitoring DB.
        """
        logging.info(f"Fetching run_results.json for Run ID: {run_id}")
        response = self.hook.get_job_run_artifact(
            account_id=self.account_id,
            run_id=run_id,
            path="run_results.json"
        )
        
        # Parse the bytes into JSON
        try:
            artifact_json = json.loads(response.read().decode('utf-8'))
            logging.info(f"Successfully retrieved artifact. Parsed {len(artifact_json.get('results', []))} node results.")
            return artifact_json
        except Exception as e:
            logging.error(f"Failed to parse run_results.json: {e}")
            raise
