import pytest
from unittest.mock import MagicMock

from src.exceptions.hierarchy import (
    SnowflakeConnectionException, 
    DataQualityException
)
from src.exceptions.retry import enterprise_retry_policy

def test_retry_on_transient_exception():
    """Test that a RetryableException triggers retries until max attempts."""
    mock_func = MagicMock(side_effect=SnowflakeConnectionException("Transient Timeout"))
    
    # Configure retry policy to run extremely fast for tests (no backoff wait)
    retry_decorator = enterprise_retry_policy(max_attempts=3, initial_wait=0, max_wait=0)
    decorated_func = retry_decorator(mock_func)
    
    with pytest.raises(SnowflakeConnectionException):
        decorated_func()
        
    # The function should have been called exactly 3 times before failing
    assert mock_func.call_count == 3

def test_fail_fast_on_non_retryable_exception():
    """Test that a NonRetryableException fails immediately without retrying."""
    mock_func = MagicMock(side_effect=DataQualityException("Null value found in PK"))
    
    retry_decorator = enterprise_retry_policy(max_attempts=3, initial_wait=0, max_wait=0)
    decorated_func = retry_decorator(mock_func)
    
    with pytest.raises(DataQualityException):
        decorated_func()
        
    # The function should have been called exactly 1 time (failed fast)
    assert mock_func.call_count == 1
