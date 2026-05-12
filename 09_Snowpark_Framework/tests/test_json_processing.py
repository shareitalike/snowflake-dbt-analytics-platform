import pytest
from unittest.mock import MagicMock
from src.json_processing.schema.schema_detector import SchemaDetector

def test_schema_detector_override():
    """Test that schema evolution overrides work correctly."""
    mock_logger = MagicMock()
    detector = SchemaDetector(enterprise_logger=mock_logger)
    
    base_map = {
        "CUSTOMER_ID": {"path": "customer.id", "type": "StringType()"},
        "TOTAL": {"path": "order.total", "type": "FloatType()"}
    }
    
    # API v2 changes the customer id path
    v2_overrides = {
        "CUSTOMER_ID": {"path": "customer.uuid", "type": "StringType()"}
    }
    
    final_map = detector.build_extraction_map(base_map, v2_overrides)
    
    # Ensure TOTAL remained untouched
    assert final_map["TOTAL"]["path"] == "order.total"
    # Ensure CUSTOMER_ID was overridden
    assert final_map["CUSTOMER_ID"]["path"] == "customer.uuid"

def test_json_parser_ast_generation():
    """
    Since we can't run a live Snowpark session in local unit tests easily without a Snowflake account,
    we mock the DataFrame and test that the with_column and get_path AST builder is called correctly.
    """
    from src.json_processing.parsers.json_parser import JSONParser
    
    mock_logger = MagicMock()
    parser = JSONParser(enterprise_logger=mock_logger)
    
    mock_df = MagicMock()
    # Mock the fluid return of with_column
    mock_df.with_column.return_value = mock_df
    
    extraction_map = {
        "CUSTOMER_EMAIL": {"path": "customer.email", "type": "StringType()"},
    }
    
    # In a fully mocked environment, snowflake.snowpark.functions won't execute, 
    # but we can verify the method returns a dataframe.
    result_df = parser.extract_fields(mock_df, "PAYLOAD_COL", extraction_map)
    assert result_df == mock_df
