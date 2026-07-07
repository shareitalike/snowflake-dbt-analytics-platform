import pytest
from unittest.mock import patch, MagicMock

from src.session.session_factory import SnowparkSessionFactory
from src.utilities.exceptions import SnowparkConnectionError

# Mock dependencies to test logic without connecting to Snowflake
@pytest.fixture
def mock_config():
    mock = MagicMock()
    mock.session.max_retries = 2
    mock.session.retry_backoff_seconds = 1
    mock.secrets.strategy = "env"
    mock.snowflake.account = "test_account"
    return mock

@patch("src.credentials.secrets_manager.SecretsManager.get_credentials")
@patch("src.session.session_factory.Session")
def test_session_factory_success(mock_session_cls, mock_secrets, mock_config):
    """Test that the factory builds a session and runs a health check."""
    mock_secrets.return_value = {"user": "test_user", "password": "test_password"}
    
    # Mock the builder chain: Session.builder.configs().create()
    mock_builder = MagicMock()
    mock_session_instance = MagicMock()
    mock_builder.configs.return_value = mock_builder
    mock_builder.create.return_value = mock_session_instance
    mock_session_cls.builder = mock_builder

    factory = SnowparkSessionFactory(config=mock_config)
    
    with factory as session:
        assert session == mock_session_instance
        # Verify health check was called
        mock_session_instance.sql.assert_called_with("SELECT 1")
        mock_session_instance.sql().collect.assert_called_once()
        
    # Verify close was called gracefully on exit
    mock_session_instance.close.assert_called_once()

@patch("src.credentials.secrets_manager.SecretsManager.get_credentials")
@patch("src.session.session_factory.Session")
def test_session_factory_exhausted_retries(mock_session_cls, mock_secrets, mock_config):
    """Test that exponential backoff exhausts retries and raises our custom error."""
    mock_secrets.return_value = {"user": "test_user", "password": "test_password"}
    
    from snowflake.connector.errors import OperationalError
    
    mock_builder = MagicMock()
    mock_builder.configs.return_value = mock_builder
    # Force the connection to fail repeatedly
    mock_builder.create.side_effect = OperationalError("Simulated Network Drop")
    mock_session_cls.builder = mock_builder

    factory = SnowparkSessionFactory(config=mock_config)
    
    with pytest.raises(SnowparkConnectionError) as exc_info:
        with factory as session:
            pass
            
    assert "Session Factory exhausted retries" in str(exc_info.value)
