"""
==============================================================================
FILE: enterprise_stream_sensor.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: A custom Airflow Sensor that periodically polls a Snowflake CDC Stream to verify if new data has arrived before allowing downstream tasks to execute.
DESIGN DECISIONS: Forces mode='reschedule' by default to immediately release the Airflow worker thread if the stream is empty, checking again after the poke_interval.
WHY: If the source system (e.g., Salesforce) hasn't generated any new records, running a heavy Snowflake MERGE statement is a waste of compute credits. This sensor acts as a cheap "gatekeeper," preventing unnecessary warehouse wake-ups.
==============================================================================
"""
from airflow.sensors.base import BaseSensorOperator
from hooks.snowflake.enterprise_snowflake_hook import EnterpriseSnowflakeHook
import logging

class EnterpriseStreamSensor(BaseSensorOperator):
    """
    Waits for a Snowflake Stream to contain data before allowing the DAG to proceed.
    """
    def __init__(self, 
                 stream_name: str, 
                 snowflake_conn_id: str = 'snowflake_default',
                 *args, **kwargs):
        # Force 'reschedule' mode by default to prevent Worker thread blocking
        kwargs.setdefault('mode', 'reschedule')
        super().__init__(*args, **kwargs)
        self.stream_name = stream_name
        self.snowflake_conn_id = snowflake_conn_id

    def poke(self, context) -> bool:
        logging.info(f"Poking Snowflake Stream: {self.stream_name}")
        hook = EnterpriseSnowflakeHook(snowflake_conn_id=self.snowflake_conn_id)
        
        has_data = hook.check_stream_has_data(self.stream_name)
        
        if has_data:
            logging.info(f"Stream {self.stream_name} has data. Sensor succeeded.")
            return True
        else:
            logging.info(f"Stream {self.stream_name} is empty. Rescheduling...")
            return False
