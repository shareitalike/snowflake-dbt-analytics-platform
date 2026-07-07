"""
Enterprise Snowflake Operator
Extends the native SnowflakeOperator to add pre-flight checks, 
Stream validations, and dynamic Warehouse resuming.
"""
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from hooks.snowflake.enterprise_snowflake_hook import EnterpriseSnowflakeHook
import logging

class EnterpriseSnowflakeOperator(SnowflakeOperator):
    """
    OmniRetail custom operator wrapping native SnowflakeOperator.
    Adds transaction safety, stream validation, and pre-flight checks.
    """
    
    def __init__(self, 
                 stream_to_check: str = None, 
                 require_warehouse_resume: bool = False,
                 *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.stream_to_check = stream_to_check
        self.require_warehouse_resume = require_warehouse_resume

    def get_hook(self) -> EnterpriseSnowflakeHook:
        """Override to return our custom Enterprise Hook instead of the default."""
        return EnterpriseSnowflakeHook(snowflake_conn_id=self.snowflake_conn_id)

    def execute(self, context):
        hook = self.get_hook()
        
        # 1. Pre-Flight Warehouse Check
        if self.require_warehouse_resume and self.warehouse:
            logging.info("Executing Pre-Flight Warehouse Health Check...")
            hook.validate_warehouse_health(self.warehouse)
            
        # 2. Pre-Flight Stream Check (Conditional Execution)
        if self.stream_to_check:
            logging.info(f"Checking if stream {self.stream_to_check} has data...")
            has_data = hook.check_stream_has_data(self.stream_to_check)
            if not has_data:
                logging.info("Stream is empty. Skipping SQL execution.")
                return "SKIPPED_EMPTY_STREAM"
                
        # 3. Transaction wrapping
        # If autocommit is false, we explicitly wrap in BEGIN/COMMIT
        if not self.autocommit:
            logging.info("Wrapping SQL in explicit transaction block...")
            self.sql = f"BEGIN;\n{self.sql}\nCOMMIT;"
            
        try:
            # Execute the core SQL (Task, Stored Proc, or raw SQL)
            logging.info("Executing SQL payload...")
            return super().execute(context)
        except Exception as e:
            # 4. Error Handling and Rollback
            if not self.autocommit:
                logging.error("Execution failed. Issuing explicit ROLLBACK.")
                hook.run("ROLLBACK;")
            logging.error(f"Snowflake execution failed: {str(e)}")
            raise e
