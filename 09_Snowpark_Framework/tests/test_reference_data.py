import pytest
from unittest.mock import MagicMock
from src.reference_data.cache.reference_cache import ReferenceCache
from src.exceptions.hierarchy import ConfigurationException

def test_reference_cache_exceeds_limit():
    """Test that attempting to cache a massive table throws ConfigurationException."""
    mock_logger = MagicMock()
    # Very small limit for test
    cache = ReferenceCache(enterprise_logger=mock_logger, max_rows=5)
    
    mock_df = MagicMock()
    # Simulate a table with 10 rows
    mock_df.count.return_value = 10
    
    with pytest.raises(ConfigurationException) as excinfo:
        cache.load_cache("STATE_CODES", mock_df, "code", "name")
        
    assert "exceeds max cache size" in str(excinfo.value)
    
def test_reference_cache_success():
    """Test successful cache loading into memory."""
    mock_logger = MagicMock()
    cache = ReferenceCache(enterprise_logger=mock_logger, max_rows=100)
    
    mock_df = MagicMock()
    mock_df.count.return_value = 2
    
    # Mocking Snowpark Row behavior
    mock_row1 = {"code": "CA", "name": "California"}
    mock_row2 = {"code": "NY", "name": "New York"}
    
    mock_select = MagicMock()
    mock_select.collect.return_value = [mock_row1, mock_row2]
    mock_df.select.return_value = mock_select
    
    cache.load_cache("STATE_CODES", mock_df, "code", "name")
    
    # Verify the internal dictionary
    result = cache.get_dict("STATE_CODES")
    assert result["CA"] == "California"
    assert result["NY"] == "New York"
