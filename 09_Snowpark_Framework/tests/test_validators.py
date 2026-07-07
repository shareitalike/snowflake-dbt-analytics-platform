import pytest
from unittest.mock import MagicMock
from src.validators.schema.schema_validator import SchemaValidator
from src.exceptions.hierarchy import SchemaValidationException

def test_schema_validator_missing_column():
    """Tests that missing required columns raise a SchemaValidationException."""
    mock_logger = MagicMock()
    validator = SchemaValidator(enterprise_logger=mock_logger)
    
    # Mocking Snowpark DataFrame schema
    mock_df = MagicMock()
    
    mock_field1 = MagicMock()
    mock_field1.name = "ID"
    mock_field1.datatype.__class__.__name__ = "LongType"
    
    mock_df.schema.fields = [mock_field1]
    
    # We expect ID and NAME
    expected_schema = {"ID": "LongType", "NAME": "StringType"}
    
    with pytest.raises(SchemaValidationException) as excinfo:
        validator.validate_schema(mock_df, expected_schema)
        
    assert "Missing required columns" in str(excinfo.value)
    assert "NAME" in str(excinfo.value)

def test_schema_validator_additive_evolution():
    """Tests that unexpected columns pass validation when strict=False."""
    mock_logger = MagicMock()
    validator = SchemaValidator(enterprise_logger=mock_logger)
    
    # Mocking Snowpark DataFrame schema with an extra column
    mock_df = MagicMock()
    
    mock_field1 = MagicMock()
    mock_field1.name = "ID"
    mock_field1.datatype.__class__.__name__ = "LongType"
    
    mock_field2 = MagicMock()
    mock_field2.name = "NEW_COLUMN"
    mock_field2.datatype.__class__.__name__ = "StringType"
    
    mock_df.schema.fields = [mock_field1, mock_field2]
    
    # We only expect ID
    expected_schema = {"ID": "LongType"}
    
    # Should not raise exception
    validator.validate_schema(mock_df, expected_schema, strict=False)
    
    # But should log a warning info
    mock_logger.info.assert_any_call("Unexpected columns found (Additive Schema Evolution): ['NEW_COLUMN']")

def test_schema_validator_strict_mode():
    """Tests that unexpected columns fail validation when strict=True."""
    mock_logger = MagicMock()
    validator = SchemaValidator(enterprise_logger=mock_logger)
    
    mock_df = MagicMock()
    
    mock_field1 = MagicMock()
    mock_field1.name = "ID"
    mock_field1.datatype.__class__.__name__ = "LongType"
    
    mock_field2 = MagicMock()
    mock_field2.name = "NEW_COLUMN"
    mock_field2.datatype.__class__.__name__ = "StringType"
    
    mock_df.schema.fields = [mock_field1, mock_field2]
    
    expected_schema = {"ID": "LongType"}
    
    with pytest.raises(SchemaValidationException) as excinfo:
        validator.validate_schema(mock_df, expected_schema, strict=True)
        
    assert "Strict mode enabled. Failing on unexpected columns" in str(excinfo.value)
