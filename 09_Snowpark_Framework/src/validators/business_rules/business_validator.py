import logging
from typing import Tuple, Optional

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col, current_date, lit, length
except ImportError:
    pass

from src.exceptions.hierarchy import BusinessRuleException
from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class RetailBusinessValidator:
    """
    Tier 3 Business Validation Framework - Retail Domain.
    Applies complex domain logic and referential integrity specific to the OmniRetail Platform.
    Returns (clean_df, dirty_df, rejection_reason) for DLQ routing.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def _split_and_label(self, df: DataFrame, valid_condition, rejection_reason: str) -> Tuple[DataFrame, DataFrame]:
        """Helper to split dataframes and label the dirty ones."""
        clean_df = df.filter(valid_condition)
        dirty_df = df.filter(~valid_condition).with_column("DLQ_REASON", lit(rejection_reason))
        return clean_df, dirty_df

    # =========================================================================
    # CUSTOMER DOMAIN
    # =========================================================================
    def validate_customer_loyalty_eligibility(self, df: DataFrame) -> Tuple[DataFrame, DataFrame]:
        """
        Customer Rule: Age >= 18 for loyalty enrollment.
        Valid email format.
        """
        self.logger.info("Validating Customer Domain: Loyalty Age (>=18) and Email format.")
        
        # Age >= 18
        valid_age = col("age") >= lit(18)
        
        # Simple email regex matching
        valid_email = col("email").rlike(lit("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"))
        
        return self._split_and_label(df, valid_age & valid_email, "CUSTOMER_RULE_VIOLATION_LOYALTY")

    # =========================================================================
    # ORDER DOMAIN
    # =========================================================================
    def validate_order_totals(self, df: DataFrame) -> Tuple[DataFrame, DataFrame]:
        """
        Order Rule: Order total equals sum of order items (subtotal + tax + shipping).
        Order date cannot be in the future.
        """
        self.logger.info("Validating Order Domain: Totals and Dates.")
        
        valid_total = col("order_total") == (col("subtotal") + col("tax_amount") + col("shipping_amount"))
        valid_date = col("order_date") <= current_date()
        
        return self._split_and_label(df, valid_total & valid_date, "ORDER_RULE_VIOLATION")

    # =========================================================================
    # PAYMENT DOMAIN
    # =========================================================================
    def validate_payment_match(self, df: DataFrame, orders_df: DataFrame) -> Tuple[DataFrame, DataFrame]:
        """
        Payment Rule: Payment amount must exactly match the billed order amount.
        (Requires joining against the Orders DataFrame).
        """
        self.logger.info("Validating Payment Domain: Payment amount equals Order amount.")
        
        # Join payments to orders to verify totals
        joined_df = df.join(orders_df, df.order_id == orders_df.order_id, "left")
        
        valid_payment = col("payment_amount") == col("order_total")
        
        # We return the original payment schema by dropping the order columns after check
        clean_joined = joined_df.filter(valid_payment)
        dirty_joined = joined_df.filter(~valid_payment).with_column("DLQ_REASON", lit("PAYMENT_AMOUNT_MISMATCH"))
        
        # Assuming original df columns are what we want to return
        cols = [col(c) for c in df.columns]
        
        clean_df = clean_joined.select(*cols)
        dirty_df = dirty_joined.select(*cols, col("DLQ_REASON"))
        
        return clean_df, dirty_df

    # =========================================================================
    # INVENTORY DOMAIN
    # =========================================================================
    def validate_inventory_stock(self, df: DataFrame) -> Tuple[DataFrame, DataFrame]:
        """
        Inventory Rule: Stock quantity cannot be negative. 
        Reorder thresholds must be logically valid (reorder_point < max_capacity).
        """
        self.logger.info("Validating Inventory Domain: Stock bounds.")
        
        valid_stock = col("quantity_on_hand") >= lit(0)
        valid_thresholds = col("reorder_point") < col("max_capacity")
        
        return self._split_and_label(df, valid_stock & valid_thresholds, "INVENTORY_RULE_VIOLATION")

    # =========================================================================
    # RETURN DOMAIN
    # =========================================================================
    def validate_return_policy(self, df: DataFrame) -> Tuple[DataFrame, DataFrame]:
        """
        Return Rule: Returned quantity <= purchased quantity.
        (Assuming purchased_quantity is brought in via an upstream join before this validator).
        """
        self.logger.info("Validating Return Domain: Return Quantities.")
        
        valid_qty = col("returned_quantity") <= col("purchased_quantity")
        valid_reason = length(col("return_reason")) > lit(0)
        
        return self._split_and_label(df, valid_qty & valid_reason, "RETURN_POLICY_VIOLATION")

    # =========================================================================
    # PROMOTION DOMAIN
    # =========================================================================
    def validate_promotions(self, df: DataFrame) -> Tuple[DataFrame, DataFrame]:
        """
        Promotion Rule: Validity dates are logical (start <= end).
        Discount percentage within business limits (0 to 100%).
        """
        self.logger.info("Validating Promotion Domain: Dates and Discount limits.")
        
        valid_dates = col("start_date") <= col("end_date")
        valid_discount = (col("discount_percentage") > lit(0)) & (col("discount_percentage") <= lit(100))
        
        return self._split_and_label(df, valid_dates & valid_discount, "PROMOTION_RULE_VIOLATION")
