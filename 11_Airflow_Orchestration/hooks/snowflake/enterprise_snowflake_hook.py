"""
Enterprise Snowflake Hook
Extends the native Airflow SnowflakeHook with robust Enterprise Validation, 
Warehouse Management, and Credit Monitoring capabilities.
"""
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
import logging

class EnterpriseSnowflakeHook(SnowflakeHook):
    """
    Custom OmniRetail Hook wrapping Snowflake execution with deep validation.
    """
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def validate_warehouse_health(self, warehouse_name: str) -> bool:
        """
        Ensures the warehouse is active and not suspended before submitting heavy queries.
        """
        sql = f"SHOW WAREHOUSES LIKE '{warehouse_name}';"
        result = self.get_first(sql)
        if not result:
            raise ValueError(f"Warehouse {warehouse_name} does not exist.")
        
        state = result['state']
        logging.info(f"Warehouse {warehouse_name} is currently in state: {state}")
        
        if state == 'SUSPENDED':
            logging.info(f"Resuming warehouse {warehouse_name}...")
            self.run(f"ALTER WAREHOUSE {warehouse_name} RESUME IF SUSPENDED;")
            return True
        elif state == 'STARTED':
            return True
        else:
            raise Exception(f"Warehouse in invalid state: {state}")

    def validate_role_permissions(self, role_name: str, schema_name: str) -> bool:
        """
        Validates if the executing role has USAGE on the target schema.
        Prevents blind 'Permission Denied' errors mid-DAG.
        """
        sql = f"SHOW GRANTS TO ROLE {role_name};"
        grants = self.get_records(sql)
        for grant in grants:
            # grant format varies, but index 1 is usually privilege, index 3 is object name
            if grant[1] == 'USAGE' and schema_name in grant[3]:
                logging.info(f"Role {role_name} validated for schema {schema_name}.")
                return True
        raise PermissionError(f"Role {role_name} lacks USAGE on {schema_name}.")

    def check_stream_has_data(self, stream_name: str) -> bool:
        """
        Used by Operators to determine if they should execute downstream tasks, 
        or skip them if the CDC stream is empty.
        """
        sql = f"SELECT SYSTEM$STREAM_HAS_DATA('{stream_name}');"
        result = self.get_first(sql)
        has_data = result[0]
        logging.info(f"Stream {stream_name} has data: {has_data}")
        return has_data

    def monitor_warehouse_credits(self, warehouse_name: str, threshold: int) -> bool:
        """
        Checks if the warehouse has burned through too many credits today.
        """
        sql = f"""
            SELECT SUM(CREDITS_USED) 
            FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY 
            WHERE WAREHOUSE_NAME = '{warehouse_name}' 
            AND START_TIME >= CURRENT_DATE();
        """
        result = self.get_first(sql)
        credits_used = result[0] or 0
        logging.info(f"Warehouse {warehouse_name} has consumed {credits_used} credits today.")
        
        if credits_used > threshold:
            logging.warning(f"Credit Threshold Exceeded! Used {credits_used} > {threshold}")
            return False
        return True
