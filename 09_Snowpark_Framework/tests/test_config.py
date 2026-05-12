import os
import pytest
from unittest.mock import patch

from src.session.config_loader import ConfigLoader, AppConfig
from src.utilities.exceptions import ConfigurationError

@patch.dict(os.environ, {"ENVIRONMENT": "dev"})
def test_config_loader_success():
    """Test that the DEV configuration loads and parses correctly."""
    config = ConfigLoader.load_config()
    
    # Assertions based on dev.toml
    assert isinstance(config, AppConfig)
    assert config.environment.name == "development"
    assert config.snowflake.role == "DATA_ENGINEER_DEV"
    assert config.session.max_retries == 3
    assert config.secrets.strategy == "env"

@patch.dict(os.environ, {"ENVIRONMENT": "prod"})
def test_config_loader_prod_success():
    """Test that the PROD configuration enforces correct values."""
    config = ConfigLoader.load_config()
    
    assert config.environment.name == "production"
    assert config.session.timeout_ms == 1800000
    assert config.secrets.strategy == "aws_secrets_manager"

@patch.dict(os.environ, {"ENVIRONMENT": "nonexistent"})
def test_config_loader_missing_file():
    """Test that a missing TOML file raises the custom ConfigurationError."""
    with pytest.raises(ConfigurationError) as exc_info:
        ConfigLoader.load_config()
        
    assert "Configuration file not found" in str(exc_info.value)
