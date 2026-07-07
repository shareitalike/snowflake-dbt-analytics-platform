import pytest
from unittest.mock import MagicMock
from src.reference_data.lookup_engine.lookup_manager import LookupManager
from src.exceptions.hierarchy import ConfigurationException

def test_lookup_manager_routing():
    """Test that the LookupManager routes requests to the correct resolvers."""
    mock_logger = MagicMock()
    manager = LookupManager(enterprise_logger=mock_logger)
    
    mock_df = MagicMock()
    
    # We mock the internal imports/instantiations if needed, but since Snowpark functions aren't 
    # executing locally, we mostly want to verify it doesn't crash on valid types 
    # and DOES crash on invalid types.
    
    with pytest.raises(ConfigurationException) as excinfo:
        manager.resolve(mock_df, "UNKNOWN_RESOLVER")
        
    assert "Unsupported resolver type" in str(excinfo.value)
    
def test_hierarchy_fallback():
    """Test the logical fallback mechanism in HierarchyResolver."""
    from src.reference_data.dimensions.hierarchy_resolver import HierarchyResolver
    
    mock_logger = MagicMock()
    resolver = HierarchyResolver(enterprise_logger=mock_logger)
    
    mock_df = MagicMock()
    mock_hierarchy_df = MagicMock()
    
    # Mock the join and with_column chaining
    mock_joined = MagicMock()
    mock_df.join.return_value = mock_joined
    mock_joined.with_column.return_value = mock_joined
    
    result = resolver.resolve_hierarchy(
        mock_df, 
        mock_hierarchy_df, 
        child_key="sub_category_id",
        parent_col_name="parent_category"
    )
    
    # Verify join was called
    assert mock_df.join.called
    # Verify with_column was called twice (once for value, once for warning)
    assert mock_joined.with_column.call_count == 2
