import logging

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import coalesce, lit, when
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class HierarchyResolver:
    """
    Resolves multi-level parent-child hierarchies (e.g. Category -> Subcategory).
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def resolve_hierarchy(
        self, 
        df: DataFrame, 
        hierarchy_df: DataFrame, 
        child_key: str,
        parent_col_name: str,
        default_fallback: str = "UNMAPPED_PARENT"
    ) -> DataFrame:
        """
        Resolves a parent node based on a child key.
        Hierarchies are usually structurally static (Type 1 SCD), so we may not need temporal bounds here,
        but it can be added if the hierarchy evolves.
        """
        self.logger.info(f"Resolving Hierarchy Parent for '{child_key}'.")
        
        join_condition = (df[child_key] == hierarchy_df[child_key])
        
        joined_df = df.join(hierarchy_df, join_condition, "left")
        
        resolved_df = joined_df.with_column(
            parent_col_name,
            coalesce(hierarchy_df[parent_col_name], lit(default_fallback))
        ).with_column(
            f"{parent_col_name}_WARNING",
            when(hierarchy_df[parent_col_name].is_null(), lit("ORPHANED_CHILD_NODE")).else_(lit(None))
        )
        
        return resolved_df
