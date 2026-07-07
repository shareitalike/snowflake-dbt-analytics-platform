import logging
from typing import List, Optional

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col, table_function, parse_json
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class ArrayFlattener:
    """
    Handles LATERAL FLATTEN operations for expanding JSON Arrays into rows.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def flatten_array(self, df: DataFrame, array_col: str, path: str = "", outer: bool = False) -> DataFrame:
        """
        Explodes a JSON array into multiple rows using Snowflake's FLATTEN table function.
        
        Args:
            df: Snowpark DataFrame.
            array_col: The column containing the array or the VARIANT object containing the array.
            path: The path within the VARIANT column pointing to the array (leave empty if column is directly the array).
            outer: If True, generates a row with NULLs even if the array is empty (LEFT JOIN behavior).
            
        Returns:
            DataFrame with the exploded 'VALUE' column containing individual array elements.
        """
        self.logger.info(f"Flattening array at '{array_col}:{path}' (Outer: {outer})")
        
        # Load the flatten table function
        flatten_tf = table_function("flatten")
        
        # Determine the input to flatten
        if path:
            flatten_input = flatten_tf(input=col(array_col), path=path, outer=outer)
        else:
            flatten_input = flatten_tf(input=col(array_col), outer=outer)
            
        # Perform the lateral join
        flattened_df = df.join_table_function(flatten_input)
        
        # The result includes standard FLATTEN columns: SEQ, KEY, PATH, INDEX, VALUE, THIS
        # We rename 'VALUE' to something specific to avoid collisions on multiple flattens.
        flattened_df = flattened_df.with_column_renamed("VALUE", f"{array_col}_item")
        
        return flattened_df
