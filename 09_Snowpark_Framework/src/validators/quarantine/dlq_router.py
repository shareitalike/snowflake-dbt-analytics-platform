import logging

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import current_timestamp
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class DLQRouter:
    """
    Quarantine Framework (Dead Letter Queue).
    Routes failed records to the quarantine schemas for data steward review.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def route_to_quarantine(self, dirty_df: DataFrame, target_table: str, pipeline_run_id: str):
        """
        Appends audit metadata and writes the dirty records to the DLQ.
        """
        try:
            # Avoid lazy evaluation failing if the dataframe is empty by doing a quick count,
            # or just rely on Snowpark's optimize to write 0 rows if empty.
            count = dirty_df.count()
            if count == 0:
                self.logger.info(f"No records to route to quarantine table {target_table}.")
                return

            self.logger.info(f"Routing {count} invalid records to {target_table}.")
            
            # Append Audit columns
            quarantine_df = dirty_df.with_column("DLQ_TIMESTAMP", current_timestamp())
            
            # Write to DLQ Schema (using append)
            quarantine_df.write.mode("append").save_as_table(target_table)
            
            self.logger.info(f"Successfully quarantined {count} records.")
            
        except Exception as e:
            self.logger.error(f"Failed to route records to DLQ: {str(e)}")
            # Raise exception because if we can't save bad records, we shouldn't proceed
            # and potentially lose data.
            raise
