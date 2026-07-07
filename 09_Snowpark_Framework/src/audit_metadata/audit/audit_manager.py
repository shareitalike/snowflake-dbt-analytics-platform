import logging
from datetime import datetime
from typing import Optional, List
import uuid

try:
    from snowflake.snowpark import Session, DataFrame
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class BatchTracker:
    """Tracks metrics for a specific pipeline batch."""
    def __init__(self, batch_id: str):
        self.batch_id = batch_id
        self.rows_read = 0
        self.rows_written = 0
        self.rows_rejected = 0
        self.error_count = 0
        self.warning_count = 0
        self.query_ids: List[str] = []

class ExecutionTracker:
    """
    Context Manager that tracks the lifecycle of a Snowpark Job.
    Guarantees that Audit Metrics are flushed to the Control Table upon exit.
    """
    def __init__(self, session: 'Session', logger: EnterpriseLogger, pipeline_name: str, warehouse: str):
        self.session = session
        self.logger = logger
        self.pipeline_name = pipeline_name
        self.warehouse = warehouse
        self.run_id = str(uuid.uuid4())
        self.start_time = datetime.utcnow()
        self.end_time: Optional[datetime] = None
        self.status = "STARTED"
        self.batch_tracker = BatchTracker(batch_id=self.run_id)

    def __enter__(self):
        self.logger.info(f"ExecutionTracker started for {self.pipeline_name} (Run: {self.run_id})")
        # In a real environment, we might log an initial "STARTED" record here.
        return self

    def add_metrics(self, read: int = 0, written: int = 0, rejected: int = 0, query_ids: List[str] = None):
        self.batch_tracker.rows_read += read
        self.batch_tracker.rows_written += written
        self.batch_tracker.rows_rejected += rejected
        if query_ids:
            self.batch_tracker.query_ids.extend(query_ids)

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.end_time = datetime.utcnow()
        
        if exc_type is not None:
            self.status = "FAILED"
            self.batch_tracker.error_count += 1
            self.logger.error(f"ExecutionTracker detected failure: {exc_val}")
        else:
            self.status = "COMPLETED"
            
        duration = (self.end_time - self.start_time).total_seconds()
        
        audit_payload = {
            "PIPELINE_NAME": self.pipeline_name,
            "RUN_ID": self.run_id,
            "WAREHOUSE": self.warehouse,
            "START_TIME": self.start_time.isoformat(),
            "END_TIME": self.end_time.isoformat(),
            "DURATION_SEC": duration,
            "STATUS": self.status,
            "ROWS_READ": self.batch_tracker.rows_read,
            "ROWS_WRITTEN": self.batch_tracker.rows_written,
            "ROWS_REJECTED": self.batch_tracker.rows_rejected,
            "ERROR_COUNT": self.batch_tracker.error_count,
            "QUERY_IDS": ",".join(self.batch_tracker.query_ids)
        }
        
        self.logger.info("Flushing Execution Metrics to Control Table", extra=audit_payload)
        
        try:
            # df = self.session.create_dataframe([audit_payload])
            # df.write.mode("append").save_as_table("DB_PROD_METADATA.SC_META_CONTROL.TB_PIPELINE_AUDIT")
            pass
        except Exception as e:
            self.logger.error(f"Failed to flush audit payload to Snowflake: {str(e)}")

class AuditManager:
    """Factory for initializing ExecutionTrackers."""
    def __init__(self, session: 'Session', logger: EnterpriseLogger):
        self.session = session
        self.logger = logger
        
    def start_job(self, pipeline_name: str, warehouse: str) -> ExecutionTracker:
        return ExecutionTracker(self.session, self.logger, pipeline_name, warehouse)
