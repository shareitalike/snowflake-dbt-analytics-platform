import logging

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import coalesce, lit, when
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class SurrogateKeyResolver:
    """
    Resolves Snowflake BIGINT Surrogate Keys for Dimensions.
    Essential for converting natural keys to efficient analytical join keys.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def resolve_key(
        self, 
        df: DataFrame, 
        dim_df: DataFrame, 
        natural_key: str, 
        surrogate_key: str,
        transaction_date_col: str,
        default_fallback: int = -1,
        dim_start_col: str = "effective_start_date",
        dim_end_col: str = "effective_end_date"
    ) -> DataFrame:
        """
        Performs a temporal bounded join to acquire the correct Surrogate Key.
        """
        self.logger.info(f"Resolving Surrogate Key for '{natural_key}' -> '{surrogate_key}'.")
        
        join_condition = (
            (df[natural_key] == dim_df[natural_key]) &
            (df[transaction_date_col] >= dim_df[dim_start_col]) &
            (df[transaction_date_col] < dim_df[dim_end_col])
        )
        
        joined_df = df.join(dim_df, join_condition, "left")
        
        # Apply integer Fallback (-1 typically implies UNKNOWN in Star Schemas)
        resolved_df = joined_df.with_column(
            surrogate_key,
            coalesce(dim_df[surrogate_key], lit(default_fallback))
        ).with_column(
            f"{surrogate_key}_WARNING",
            when(dim_df[surrogate_key].is_null(), lit(f"MISSING_SURROGATE_KEY_{natural_key}")).else_(lit(None))
        )
        
        return resolved_df
