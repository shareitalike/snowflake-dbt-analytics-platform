"""
Module: loggers.py
Description: Core logger factory and specialized loggers (Pipeline, Audit, Performance)
"""
import sys
import logging
from typing import Dict, Any, Optional

from .formatters import JSONFormatter
from .audit_context import AuditContext, PerformanceMetrics

# Fallback import for local testing without Snowpark
try:
    from snowflake.snowpark import Session
except ImportError:
    Session = Any

class LoggerFactory:
    """
    Centralized Factory for creating properly configured JSON loggers.
    """
    @staticmethod
    def get_logger(name: str, pipeline_id: str, env: str = "dev", level: int = logging.INFO) -> logging.Logger:
        logger = logging.getLogger(name)
        
        # Prevent duplicate logs if handlers already exist or propagate is True
        if not logger.handlers:
            logger.setLevel(level)
            logger.propagate = False
            
            # All logs emit to stdout for container capture
            stream_handler = logging.StreamHandler(sys.stdout)
            stream_handler.setFormatter(JSONFormatter(pipeline_id=pipeline_id, env=env))
            logger.addHandler(stream_handler)
            
        return logger

class EnterpriseLogger:
    """
    Wrapper providing specialized logging methods for Audit, Performance, and Business Events.
    """
    def __init__(self, pipeline_id: str, env: str = "dev"):
        self.pipeline_id = pipeline_id
        self.logger = LoggerFactory.get_logger("EnterpriseLogger", pipeline_id, env)
        
    def info(self, message: str, extra: Optional[Dict[str, Any]] = None):
        self.logger.info(message, extra={"extra_context": extra} if extra else None)

    def error(self, message: str, exc_info: bool = True, extra: Optional[Dict[str, Any]] = None):
        self.logger.error(message, exc_info=exc_info, extra={"extra_context": extra} if extra else None)

    def log_business_event(self, event_name: str, payload: Dict[str, Any]):
        """Emits domain-specific business events."""
        event_wrapper = {
            "event_type": "BUSINESS_EVENT",
            "event_name": event_name,
            "payload": payload
        }
        self.info(f"Business Event: {event_name}", extra=event_wrapper)

    def log_performance_metrics(self, metrics: PerformanceMetrics):
        """Emits granular FinOps/Performance data."""
        self.info(f"Performance Metrics - Query {metrics.query_id}", extra={
            "event_type": "PERFORMANCE_METRIC",
            "metrics": metrics.model_dump()
        })

class AuditLogger:
    """
    Handles synchronous DB-level auditing. 
    Writes directly to DB_PROD_METADATA schemas via the Snowpark Session.
    """
    def __init__(self, session: Session, base_logger: EnterpriseLogger):
        self.session = session
        self.base = base_logger

    def log_pipeline_status(self, context: AuditContext):
        """
        Writes the structured AuditContext directly to the Snowflake Control Table.
        In a real implementation, this constructs an INSERT/MERGE AST using Snowpark.
        """
        # Log to stdout first
        self.base.info(f"Pipeline Audit: {context.status}", extra={
            "event_type": "AUDIT_LOG",
            "audit_context": context.model_dump(mode='json')
        })
        
        # Execute Snowpark operation (conceptual mapping for framework)
        try:
            # df = self.session.create_dataframe([context.model_dump()])
            # df.write.mode("append").save_as_table("DB_PROD_METADATA.SC_META_CONTROL.TB_PIPELINE_LOG")
            pass
        except Exception as e:
            self.base.error(f"Failed to write audit log to Snowflake: {str(e)}")
            # Intentionally not raising here to avoid crashing the shutdown sequence
