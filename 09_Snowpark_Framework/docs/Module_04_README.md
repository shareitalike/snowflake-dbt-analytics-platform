# Phase 09 - Module 4: Enterprise Data Validation Framework

This module contains the enterprise validation engine, designed to execute robust Data Quality (DQ) checks and Business Rules on Snowpark DataFrames before data reaches the curated layers.

## Deliverables Checklist

- [x] **Design Summary:** Documented the multi-tiered validation and quarantine strategy.
- [x] **Repository Structure:** Added `validators` directory containing `schema`, `quality_checks`, `business_rules`, and `quarantine`.
- [x] **Schema Validation Framework:** Implemented `SchemaValidator` to detect missing columns and type drift without incurring compute costs. Supports strict mode and additive evolution.
- [x] **Data Quality Framework:** Implemented `QualityValidator` to chain distributed rules (nulls, domains, patterns) into a single optimized Snowpark execution.
- [x] **Business Validation Framework:** Implemented `BusinessValidator` to enforce domain logic like total calculation discrepancies.
- [x] **Quarantine Framework:** Implemented `DLQRouter` to automatically isolate rejected rows into the Dead Letter Queue schemas while maintaining pipeline momentum.
- [x] **Unit Tests:** `test_validators.py` validating schema strictness and rule chaining.
- [x] **Operational Runbook:** Documented troubleshooting for duplicate keys and schema drifts.

## Usage Example (Multi-Tier Validation)

```python
from src.validators.schema.schema_validator import SchemaValidator
from src.validators.quality_checks.dq_validator import QualityValidator
from src.validators.quarantine.dlq_router import DLQRouter

# 1. Schema Validation (Pre-flight)
schema_validator = SchemaValidator(logger)
schema_validator.validate_schema(df, expected_schema={"ID": "LongType"}, strict=False)

# 2. Data Quality (Lazy Evaluation)
dq_validator = QualityValidator(logger)
dq_validator.add_null_check("ID", is_critical=True)
clean_df, dirty_df, metrics = dq_validator.evaluate(df)

# 3. Quarantine
dlq_router = DLQRouter(logger)
dlq_router.route_to_quarantine(dirty_df, "DB_PROD_RAW.SC_QUARANTINE.TB_ORDERS_DLQ", "run_123")

# Proceed to transformation with clean_df
```
