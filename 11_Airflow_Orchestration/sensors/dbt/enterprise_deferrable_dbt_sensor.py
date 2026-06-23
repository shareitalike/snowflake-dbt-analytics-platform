"""
==============================================================================
FILE: enterprise_deferrable_dbt_sensor.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: Demonstrates the modern Airflow 2.2+ Async/Deferrable paradigm by defining a custom sensor that delegates polling logic to the Airflow Triggerer.
DESIGN DECISIONS: Replaces the standard blocking time.sleep() loop with a TimeDeltaTrigger that yields execution back to the Airflow scheduler via asyncio.
WHY: In large enterprise deployments, having hundreds of standard sensors running simultaneously leads to "Sensor Deadlock" (consuming all available worker slots). Deferrable sensors allow 1 Triggerer to monitor thousands of jobs with near-zero resource overhead.
==============================================================================
"""
import asyncio
import logging
from typing import Any, Dict

from airflow.sensors.base import BaseSensorOperator
from airflow.triggers.temporal import TimeDeltaTrigger
from airflow.providers.dbt.cloud.hooks.dbt import DbtCloudHook
from datetime import timedelta

class DbtCloudJobRunTrigger(TimeDeltaTrigger):
    """
    The Async Trigger class that runs in the Airflow Triggerer process.
    """
    def __init__(self, run_id: int, dbt_cloud_conn_id: str, poke_interval: int, **kwargs):
        super().__init__(delta=timedelta(seconds=poke_interval), **kwargs)
        self.run_id = run_id
        self.dbt_cloud_conn_id = dbt_cloud_conn_id

    async def run(self):
        """Async polling logic."""
        # Note: In a production async trigger, you would use an Async HttpHook.
        # This acts as a conceptual framework for the Triggerer.
        logging.info(f"Async checking dbt Cloud run {self.run_id}...")
        yield {"status": "success"}

class EnterpriseDeferrableDbtSensor(BaseSensorOperator):
    """
    Defers execution to the Triggerer rather than using a Celery worker.
    """
    def __init__(self, 
                 run_id: int, 
                 dbt_cloud_conn_id: str = 'dbt_cloud_default',
                 poke_interval: int = 60,
                 *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.run_id = run_id
        self.dbt_cloud_conn_id = dbt_cloud_conn_id
        self.poke_interval = poke_interval

    def execute(self, context: Dict[str, Any]):
        logging.info("Suspending Celery Worker and deferring to the Triggerer...")
        # Immediately releases the worker and passes control to the Async Trigger
        self.defer(
            trigger=DbtCloudJobRunTrigger(
                run_id=self.run_id, 
                dbt_cloud_conn_id=self.dbt_cloud_conn_id,
                poke_interval=self.poke_interval
            ),
            method_name="execute_complete"
        )

    def execute_complete(self, context: Dict[str, Any], event: Dict[str, Any] = None):
        """Called when the Triggerer yields a success event."""
        logging.info(f"dbt Cloud Job {self.run_id} completed successfully via Deferrable Sensor!")
        return True
