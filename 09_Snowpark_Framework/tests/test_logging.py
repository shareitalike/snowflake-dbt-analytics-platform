import json
import logging
import pytest
from io import StringIO
from src.logging.formatters import JSONFormatter
from src.logging.loggers import LoggerFactory, EnterpriseLogger
from src.logging.audit_context import AuditContext

@pytest.fixture
def capture_logger():
    """Sets up a logger that writes to a StringIO buffer instead of sys.stdout."""
    logger = logging.getLogger("TestJSONLogger")
    logger.setLevel(logging.INFO)
    logger.propagate = False
    
    # Remove existing handlers if any
    for h in logger.handlers[:]:
        logger.removeHandler(h)
        
    log_buffer = StringIO()
    handler = logging.StreamHandler(log_buffer)
    handler.setFormatter(JSONFormatter(pipeline_id="TEST_PIPE_01", env="test"))
    logger.addHandler(handler)
    
    return logger, log_buffer

def test_json_formatter_structure(capture_logger):
    logger, buffer = capture_logger
    logger.info("This is a test message")
    
    # Parse the output
    log_output = buffer.getvalue().strip()
    log_json = json.loads(log_output)
    
    # Verify strict keys exist
    assert "timestamp" in log_json
    assert log_json["environment"] == "test"
    assert log_json["pipeline_id"] == "TEST_PIPE_01"
    assert log_json["level"] == "INFO"
    assert log_json["message"] == "This is a test message"

def test_enterprise_logger_business_event():
    # We patch sys.stdout for EnterpriseLogger internally
    from unittest.mock import patch
    with patch('sys.stdout', new_callable=StringIO) as mock_stdout:
        e_logger = EnterpriseLogger(pipeline_id="PIPE_123", env="dev")
        e_logger.log_business_event("CUSTOMER_LTV_CALCULATED", {"customer_id": "C1", "ltv": 500})
        
        output = mock_stdout.getvalue().strip()
        # Since LoggerFactory might have already attached a handler to sys.stdout in another test, 
        # we just ensure the payload structure works.
        assert "CUSTOMER_LTV_CALCULATED" in output
        assert "C1" in output

def test_audit_context_state_machine():
    context = AuditContext(
        pipeline_id="PIPE_1",
        job_name="JOB_1",
        batch_id="B_1",
        pipeline_run_id="R_1",
        warehouse="WH_TEST"
    )
    
    assert context.status == "STARTED"
    assert context.execution_end is None
    
    context.mark_completed(records_read=100, records_written=100)
    assert context.status == "COMPLETED"
    assert context.records_read == 100
    assert context.execution_end is not None

    context.mark_failed(error_count=5)
    assert context.status == "FAILED"
    assert context.error_count == 5
