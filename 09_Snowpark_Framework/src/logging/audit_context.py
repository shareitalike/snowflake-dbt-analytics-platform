"""
Module: audit_context.py
Description: Data models for structured Audit and Performance logging.
"""
from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field

class AuditContext(BaseModel):
    """
    Standardized payload for all Snowpark Pipeline executions.
    Persisted to DB_PROD_METADATA.SC_META_CONTROL.TB_PIPELINE_LOG.
    """
    pipeline_id: str
    job_name: str
    batch_id: str
    pipeline_run_id: str
    user: str = Field(default_factory=lambda: "SYSTEM")
    warehouse: str
    
    execution_start: datetime = Field(default_factory=datetime.utcnow)
    execution_end: Optional[datetime] = None
    
    records_read: int = 0
    records_written: int = 0
    error_count: int = 0
    warning_count: int = 0
    
    status: str = "STARTED"
    
    def mark_completed(self, records_read: int, records_written: int):
        self.status = "COMPLETED"
        self.records_read = records_read
        self.records_written = records_written
        self.execution_end = datetime.utcnow()

    def mark_failed(self, error_count: int = 1):
        self.status = "FAILED"
        self.error_count = error_count
        self.execution_end = datetime.utcnow()

class PerformanceMetrics(BaseModel):
    """
    Granular performance telemetry for FinOps attribution.
    """
    pipeline_id: str
    job_name: str
    query_id: str
    cpu_time_ms: int = 0
    execution_time_ms: int = 0
    memory_usage_mb: float = 0.0
    warehouse_credits_used: float = 0.0
    additional_tags: Dict[str, Any] = Field(default_factory=dict)
