import pytest
from unittest.mock import MagicMock
from src.orchestration.pipeline_orchestrator import PipelineOrchestrator

def test_pipeline_orchestrator_success():
    """Test that the orchestrator safely executes the closure and flushes metrics."""
    mock_session = MagicMock()
    mock_logger = MagicMock()
    
    orchestrator = PipelineOrchestrator(mock_session, mock_logger)
    
    # Mock business logic
    def mock_logic(session, tracker, metrics_collector):
        return {
            "rows_read": 1000,
            "rows_written": 950,
            "rows_rejected": 50
        }
        
    result = orchestrator.execute("PIPE_TEST_01", "WH_XSMALL", mock_logic)
    
    assert result is True
    # Verify logger was called to trace execution
    assert mock_logger.info.called

def test_pipeline_orchestrator_failure():
    """Test that orchestrator handles catastrophic pipeline failures without crashing."""
    mock_session = MagicMock()
    mock_logger = MagicMock()
    
    orchestrator = PipelineOrchestrator(mock_session, mock_logger)
    
    # Mock business logic that crashes
    def mock_crashing_logic(session, tracker, metrics_collector):
        raise RuntimeError("Division by zero in UDF")
        
    result = orchestrator.execute("PIPE_TEST_02", "WH_XSMALL", mock_crashing_logic)
    
    # Orchestrator should return False, not raise the exception to the caller (e.g. Airflow)
    assert result is False
    assert mock_logger.error.called
