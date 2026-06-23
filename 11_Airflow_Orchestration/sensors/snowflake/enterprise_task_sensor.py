"""
==============================================================================
FILE: enterprise_task_sensor.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: A custom Airflow Sensor that queries the Snowflake TASK_HISTORY table to verify the status of an asynchronous Snowflake Task.
DESIGN DECISIONS: Scans the past 1 hour of TASK_HISTORY. If the status is FAILED, it explicitly raises an exception to fail the Airflow task, ensuring Airflow perfectly mirrors Snowflake's internal state.
WHY: When Airflow triggers a root Snowflake Task, the SQL command returns success immediately, even if the actual Snowflake Task fails 10 minutes later. This sensor bridges that observability gap, pulling the true state back into Airflow.
==============================================================================
"""
from airflow.sensors.base import BaseSensorOperator
from hooks.snowflake.enterprise_snowflake_hook import EnterpriseSnowflakeHook
import logging
from datetime import datetime, timedelta

class EnterpriseTaskSensor(BaseSensorOperator):
    """
    Waits for a Snowflake Task to report 'SUCCEEDED' in the TASK_HISTORY table.
    """
    def __init__(self, 
                 task_name: str, 
                 snowflake_conn_id: str = 'snowflake_default',
                 *args, **kwargs):
        kwargs.setdefault('mode', 'reschedule')
        super().__init__(*args, **kwargs)
        self.task_name = task_name
        self.snowflake_conn_id = snowflake_conn_id

    def poke(self, context) -> bool:
        logging.info(f"Checking TASK_HISTORY for {self.task_name}")
        hook = EnterpriseSnowflakeHook(snowflake_conn_id=self.snowflake_conn_id)
        
        # Check if the task succeeded in the last hour
        sql = f"""
            SELECT STATE 
            FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
                SCHEDULED_TIME_RANGE_START=>DATEADD('hour', -1, CURRENT_TIMESTAMP()),
                TASK_NAME=>'{self.task_name}'))
            ORDER BY SCHEDULED_TIME DESC
            LIMIT 1;
        """
        
        result = hook.get_first(sql)
        
        if not result:
            logging.info("No task history found yet. Rescheduling...")
            return False
            
        state = result['STATE']
        
        if state == 'SUCCEEDED':
            logging.info("Snowflake Task SUCCEEDED.")
            return True
        elif state in ['FAILED', 'CANCELED']:
            # If the Snowflake task failed, we explicitly fail the Airflow Sensor
            raise Exception(f"Snowflake Task {self.task_name} terminated in state: {state}")
        else:
            logging.info(f"Snowflake Task is currently: {state}. Rescheduling...")
            return False
