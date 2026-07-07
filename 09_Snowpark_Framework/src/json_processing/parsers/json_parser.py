import logging
from typing import Dict, List, Any

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col, get_path, cast
    from snowflake.snowpark.types import DataType
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class JSONParser:
    """
    Enterprise JSON Parser for VARIANT columns.
    Extracts nested attributes dynamically using Snowpark mapping.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def extract_fields(self, df: DataFrame, variant_col: str, extraction_map: Dict[str, Dict[str, Any]]) -> DataFrame:
        """
        Dynamically extracts fields from a JSON Variant column.
        
        Args:
            df: Snowpark DataFrame containing the VARIANT column.
            variant_col: The name of the column holding the JSON payload.
            extraction_map: Dict mapping the desired output column name to a dict containing 
                            'path' (JSON path string) and 'type' (Snowpark DataType).
                            Example: 
                            {
                                "CUSTOMER_EMAIL": {"path": "customer.email", "type": StringType()},
                                "ORDER_TOTAL": {"path": "payment.totals.amount", "type": FloatType()}
                            }
        Returns:
            DataFrame with the extracted columns appended.
        """
        self.logger.info(f"Extracting {len(extraction_map)} fields from '{variant_col}'.")
        
        extracted_df = df
        for col_name, config in extraction_map.items():
            json_path = config["path"]
            target_type = config["type"]
            
            # Using get_path to handle nested keys safely.
            # If the path doesn't exist, Snowpark evaluates to NULL safely.
            extracted_df = extracted_df.with_column(
                col_name,
                cast(get_path(col(variant_col), json_path), target_type)
            )
            
        self.logger.info("Extraction AST built successfully.")
        return extracted_df
