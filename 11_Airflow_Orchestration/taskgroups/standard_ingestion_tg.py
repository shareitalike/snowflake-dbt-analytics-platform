"""
Enterprise TaskGroup: Standard CDC Ingestion
Groups the logic of Stream Checking, Task Execution, and Watermark Updating
into a single visually collapsible UI element in Airflow.
"""
from airflow.utils.task_group import TaskGroup
from operators.snowflake.enterprise_snowflake_operator import EnterpriseSnowflakeOperator

def build_cdc_ingestion_taskgroup(group_id: str, stream_name: str, task_name: str) -> TaskGroup:
    """
    Returns a TaskGroup that handles the standard Snowflake CDC integration pattern.
    """
    with TaskGroup(group_id=group_id) as tg:
        
        # 1. We use the custom Operator to check if the stream has data.
        # If it's empty, it skips execution, saving warehouse credits.
        execute_cdc_task = EnterpriseSnowflakeOperator(
            task_id=f'execute_{task_name}',
            snowflake_conn_id='snowflake_default',
            sql=f"EXECUTE TASK omniretail.raw.{task_name};",
            stream_to_check=stream_name,
            require_warehouse_resume=True
        )

        # 2. Update Watermark table for auditability
        update_watermark = EnterpriseSnowflakeOperator(
            task_id=f'update_watermark_{stream_name}',
            snowflake_conn_id='snowflake_default',
            sql=f"""
                UPDATE omniretail.raw.cdc_watermarks 
                SET last_processed_at = CURRENT_TIMESTAMP()
                WHERE table_name = '{stream_name}';
            """
        )

        execute_cdc_task >> update_watermark
        
    return tg
