import logging
from typing import List, Dict, Any
from pydantic import BaseModel, Field

# Fallback imports for local testing without Snowpark
try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.types import StructType, StructField, DataType
except ImportError:
    DataFrame = Any
    StructType = Any
    StructField = Any
    DataType = Any

from src.exceptions.hierarchy import SchemaValidationException
from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class SchemaValidator:
    """
    Tier 1 Pre-Flight Validator.
    Ensures incoming DataFrame matches the expected structure before execution.
    """
    
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def validate_schema(self, df: DataFrame, expected_schema: Dict[str, str], strict: bool = False):
        """
        Validates a Snowpark DataFrame schema against an expected dictionary mapping.
        
        Args:
            df: The Snowpark DataFrame.
            expected_schema: Dict mapping column names to Snowflake types (e.g. {'ID': 'LongType', 'NAME': 'StringType'})
            strict: If True, fails on unexpected columns. If False, allows additive evolution.
            
        Raises:
            SchemaValidationException if destructive evolution is detected.
        """
        # Note: df.schema is evaluated locally by Snowpark, requiring no compute warehouse time.
        actual_fields = {field.name.upper(): type(field.datatype).__name__ for field in df.schema.fields}
        expected_fields = {k.upper(): v for k, v in expected_schema.items()}
        
        missing_cols = []
        type_mismatches = []
        unexpected_cols = []

        # Check for missing and mismatched types
        for col, expected_type in expected_fields.items():
            if col not in actual_fields:
                missing_cols.append(col)
            elif actual_fields[col] != expected_type:
                type_mismatches.append(f"{col} (Expected: {expected_type}, Found: {actual_fields[col]})")

        # Check for unexpected columns (additive evolution)
        for col in actual_fields.keys():
            if col not in expected_fields:
                unexpected_cols.append(col)

        # Handle findings
        if missing_cols:
            error_msg = f"Missing required columns: {missing_cols}"
            self.logger.error(error_msg)
            raise SchemaValidationException(error_msg)

        if type_mismatches:
            error_msg = f"Data type drift detected: {type_mismatches}"
            self.logger.error(error_msg)
            raise SchemaValidationException(error_msg)

        if unexpected_cols:
            warn_msg = f"Unexpected columns found (Additive Schema Evolution): {unexpected_cols}"
            if strict:
                self.logger.error(f"Strict mode enabled. Failing on unexpected columns: {unexpected_cols}")
                raise SchemaValidationException(warn_msg)
            else:
                self.logger.info(warn_msg)
                
        self.logger.info("Schema validation passed successfully.")
