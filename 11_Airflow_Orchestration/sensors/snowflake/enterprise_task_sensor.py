"""
Enterprise Task Sensor
Polls the Snowflake TASK_HISTORY table to ensure an asynchronous 
Snowflake Task has successfully completed within the expected window.
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
