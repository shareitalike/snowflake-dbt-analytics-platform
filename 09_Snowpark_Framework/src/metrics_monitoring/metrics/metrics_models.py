from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any

class PipelineMetrics(BaseModel):
    pipeline_id: str
    run_id: str
    status: str
    execution_duration_sec: float
    records_read: int = 0
    records_written: int = 0
    records_rejected: int = 0
    success_rate: float = 0.0
    retry_count: int = 0

class DataQualityMetrics(BaseModel):
    pipeline_id: str
    target_table: str
    null_percentage: float = 0.0
    duplicate_rate: float = 0.0
    schema_drift_detected: bool = False
    validation_score: float = 100.0

class BusinessMetrics(BaseModel):
    pipeline_id: str
    metric_name: str
    metric_value: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class WarehouseMetrics(BaseModel):
    warehouse_name: str
    query_id: str
    execution_time_ms: int
    queue_time_ms: int
    bytes_scanned: int
    credits_consumed_est: float = 0.0
