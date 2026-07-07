import pytest
from unittest.mock import MagicMock
from src.audit_metadata.audit.audit_manager import ExecutionTracker
from src.audit_metadata.lineage.lineage_tracker import LineageTracker, LineageNode

def test_execution_tracker_success():
    """Test the ExecutionTracker context manager on a successful run."""
    mock_session = MagicMock()
    mock_logger = MagicMock()
    
    with ExecutionTracker(mock_session, mock_logger, "TEST_PIPE", "WH_XSMALL") as tracker:
        tracker.add_metrics(read=100, written=100)
        
    assert tracker.status == "COMPLETED"
    assert tracker.batch_tracker.rows_read == 100
    assert tracker.end_time is not None
    # Verify flush to Snowflake was attempted
    mock_logger.info.assert_called_with(
        "Flushing Execution Metrics to Control Table", 
        extra=pytest.approx(dict) 
    )

def test_execution_tracker_failure():
    """Test the ExecutionTracker context manager traps exceptions and marks FAILED."""
    mock_session = MagicMock()
    mock_logger = MagicMock()
    
    with pytest.raises(ValueError):
        with ExecutionTracker(mock_session, mock_logger, "TEST_PIPE", "WH_XSMALL") as tracker:
            tracker.add_metrics(read=50)
            raise ValueError("Intentional crash")
            
    assert tracker.status == "FAILED"
    assert tracker.batch_tracker.error_count == 1
    assert tracker.batch_tracker.rows_read == 50

def test_lineage_registration():
    """Test that LineageTracker correctly registers both Technical and Business edges."""
    mock_session = MagicMock()
    mock_logger = MagicMock()
    
    tracker = LineageTracker(mock_session, mock_logger)
    
    # Technical
    api_source = LineageNode("API_SHOPIFY", "SOURCE", "API")
    raw_table = LineageNode("TB_ORDERS_RAW", "TABLE", "BRONZE")
    tracker.register_technical_dependency(api_source, raw_table, "PIPE_INGEST_SHOPIFY")
    
    # Business
    sales_fact = LineageNode("TB_SALES_FACT", "TABLE", "GOLD")
    gmv_kpi = LineageNode("GMV_KPI", "KPI", "BUSINESS_METRIC")
    tracker.register_business_dependency(sales_fact, gmv_kpi, "BI_REPORTING")
    
    assert len(tracker.edges) == 2
    assert tracker.edges[0].lineage_type == "TECHNICAL"
    assert tracker.edges[1].lineage_type == "BUSINESS"
    assert tracker.edges[1].target_id == "GMV_KPI"
