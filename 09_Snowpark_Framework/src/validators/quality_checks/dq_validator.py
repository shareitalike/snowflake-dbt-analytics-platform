import logging
from typing import List, Tuple, Dict, Any

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col, lit, sum as _sum, when
except ImportError:
    pass

from src.exceptions.hierarchy import DataQualityException
from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class QualityRule:
    def __init__(self, name: str, condition: Any, is_critical: bool = True):
        """
        condition: A Snowpark Column expression returning boolean (True means valid).
        """
        self.name = name
        self.condition = condition
        self.is_critical = is_critical

class QualityValidator:
    """
    Tier 2 Data Quality Validator.
    Builds a single lazy-evaluated query to apply multiple rules.
    """
    
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger
        self.rules: List[QualityRule] = []

    def add_null_check(self, column_name: str, is_critical: bool = True):
        self.rules.append(QualityRule(
            name=f"{column_name}_NOT_NULL",
            condition=col(column_name).is_not_null(),
            is_critical=is_critical
        ))

    def add_domain_check(self, column_name: str, allowed_values: List[str], is_critical: bool = True):
        self.rules.append(QualityRule(
            name=f"{column_name}_IN_DOMAIN",
            condition=col(column_name).in_(allowed_values),
            is_critical=is_critical
        ))
        
    def add_range_check(self, column_name: str, min_val: float, max_val: float, is_critical: bool = True):
        self.rules.append(QualityRule(
            name=f"{column_name}_IN_RANGE",
            condition=(col(column_name) >= min_val) & (col(column_name) <= max_val),
            is_critical=is_critical
        ))

    def evaluate(self, df: DataFrame) -> Tuple[DataFrame, DataFrame, Dict[str, int]]:
        """
        Evaluates all rules in a single pass.
        Returns:
            - clean_df: DataFrame with all passing records.
            - dirty_df: DataFrame with records failing at least one critical rule.
            - metrics: Dictionary of rule failure counts.
        """
        if not self.rules:
            return df, df.filter(lit(False)), {}
            
        # Combine critical rules via AND for the valid filter
        critical_condition = lit(True)
        for rule in self.rules:
            if rule.is_critical:
                critical_condition = critical_condition & rule.condition
                
        # Split dataframes (lazy evaluation)
        clean_df = df.filter(critical_condition)
        dirty_df = df.filter(~critical_condition)
        
        # In a real implementation, we would append the specific rejection reason using nested `when` clauses.
        dirty_df = dirty_df.with_column("DLQ_REASON", lit("FAILED_QUALITY_CHECK"))
        
        # Calculate metrics using agg (triggers 1 SQL query to Snowpark)
        # sum(when(~rule.condition, 1).else_(0))
        agg_exprs = [
            _sum(when(~rule.condition, lit(1)).else_(lit(0))).alias(rule.name)
            for rule in self.rules
        ]
        
        metrics_df = df.agg(*agg_exprs)
        try:
            metrics_row = metrics_df.collect()[0]
            metrics = metrics_row.as_dict()
        except Exception as e:
            self.logger.error(f"Failed to collect metrics: {str(e)}")
            metrics = {}

        self.logger.info("Data Quality Evaluation Completed", extra=metrics)
        
        return clean_df, dirty_df, metrics
