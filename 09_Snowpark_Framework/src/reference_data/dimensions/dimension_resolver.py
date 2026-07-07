import logging

try:
    from snowflake.snowpark import DataFrame
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class DimensionResolver:
    """
    Handles broad Dimension resolution fetching multiple attributes from a Dimension table.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def resolve_dimension(
        self, 
        df: DataFrame, 
        dim_df: DataFrame, 
        join_key: str,
        transaction_date_col: str
    ) -> DataFrame:
        """
        Similar to the Key Resolvers, but retains the entire Dimension schema 
        for downstream denormalization (e.g. building an OBT - One Big Table).
        """
        self.logger.info(f"Resolving full Dimension on '{join_key}'.")
        
        join_condition = (
            (df[join_key] == dim_df[join_key]) &
            (df[transaction_date_col] >= dim_df["effective_start_date"]) &
            (df[transaction_date_col] < dim_df["effective_end_date"])
        )
        
        return df.join(dim_df, join_condition, "left")
