"""
Enterprise Stream Sensor
Checks a Snowflake CDC Stream to see if new data has arrived.
If no data has arrived, it releases the Airflow Worker back to the pool
(mode='reschedule') and tries again later, saving massive compute costs.
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
