import os
import tomli
import logging
from pathlib import Path
from pydantic import BaseModel, Field

from src.utilities.exceptions import ConfigurationError

logger = logging.getLogger(__name__)

# ------------------------------------------------------------------------------
# Pydantic Schemas for Strict Type Validation
# ------------------------------------------------------------------------------
class EnvironmentConfig(BaseModel):
    name: str
    region: str = "us-east-1"
    debug_mode: bool = False

class SnowflakeConfig(BaseModel):
    account: str
    database: str
    schema_name: str = Field(alias="schema")
    role: str
    warehouse: str

class SessionConfig(BaseModel):
    timeout_ms: int = Field(default=300000, ge=0)
    max_retries: int = Field(default=3, ge=0, le=10)
    retry_backoff_seconds: int = Field(default=2, ge=1)

class SecretsConfig(BaseModel):
    strategy: str = Field(default="env")
    secret_name: str = ""

class AppConfig(BaseModel):
    environment: EnvironmentConfig
    snowflake: SnowflakeConfig
    session: SessionConfig
    secrets: SecretsConfig

# ------------------------------------------------------------------------------
# Configuration Loader Logic
# ------------------------------------------------------------------------------
class ConfigLoader:
    """
    Loads and strictly validates TOML configurations using Pydantic.
    """
    
    @staticmethod
    def load_config() -> AppConfig:
        """
        Determines the current environment, parses the TOML file, 
        and returns a validated Pydantic AppConfig model.
        """
        env = os.getenv("ENVIRONMENT", "dev").lower()
        
        # Resolve path to config file relative to project root
        current_dir = Path(__file__).resolve().parent
        project_root = current_dir.parent.parent
        config_path = project_root / "config" / "environments" / f"{env}.toml"
        
        if not config_path.exists():
            raise ConfigurationError(f"Configuration file not found: {config_path}")
            
        logger.info(f"Loading configuration for environment: {env.upper()} from {config_path}")
        
        try:
            with open(config_path, "rb") as f:
                toml_dict = tomli.load(f)
        except Exception as e:
            raise ConfigurationError(f"Failed to parse TOML file at {config_path}: {str(e)}")
            
        try:
            # Pydantic will raise ValidationError if types mismatch
            validated_config = AppConfig(**toml_dict)
            return validated_config
        except Exception as e:
            raise ConfigurationError(f"Configuration validation failed: {str(e)}")
