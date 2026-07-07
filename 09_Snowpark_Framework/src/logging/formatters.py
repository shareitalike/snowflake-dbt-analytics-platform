"""
Module: formatters.py
Description: Enforces 100% structured JSON logging across the framework.
"""
import json
import logging
from datetime import datetime

class JSONFormatter(logging.Formatter):
    """
    Custom formatter that intercepts all Python logger events
    and converts them into a strictly structured JSON string.
    Ideal for ingestion by Datadog, Splunk, or CloudWatch.
    """
    def __init__(self, pipeline_id: str = "UNKNOWN", env: str = "dev"):
        super().__init__()
        self.pipeline_id = pipeline_id
        self.env = env

    def format(self, record: logging.LogRecord) -> str:
        log_obj = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "environment": self.env,
            "pipeline_id": self.pipeline_id,
            "level": record.levelname,
            "module": record.module,
            "funcName": record.funcName,
            "message": record.getMessage()
        }
        
        if record.exc_info:
            log_obj["exception"] = self.formatException(record.exc_info)
            
        # If extra dictionary was passed, merge it (e.g. business events)
        if hasattr(record, 'extra_context'):
            log_obj["extra_context"] = record.extra_context

        return json.dumps(log_obj)
