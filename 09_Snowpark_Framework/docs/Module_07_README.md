# Phase 09 - Module 7: Enterprise Reference Data & Lookup Framework

This module elevates reference data lookups from simple static joins to fully temporal, SCD-aware caching engines supporting all core enterprise domains.

## Deliverables Checklist

- [x] **Design Summary:** Documented the SCD bounded join logic, Surrogate/Business key resolution, and caching mechanics.
- [x] **Repository Structure:** Created `reference_data/` with `lookup_engine`, `dimensions`, `cache`, and `fallback`.
- [x] **Lookup Manager:** Implemented `LookupManager` as the central orchestrator routing to specific resolution strategies.
- [x] **Key Resolvers:** Implemented `SurrogateKeyResolver` and `BusinessKeyResolver` enforcing temporal bounds.
- [x] **Dimension Resolvers:** Implemented `DimensionResolver` and `HierarchyResolver` for broad entity integration.
- [x] **Fallback Engine:** Hardened the resolvers to assign default values (`UNMAPPED`, `-1`) and flag DQ warnings instead of dropping critical revenue transactions.
- [x] **Unit Tests:** `test_reference_data_v2.py` validating orchestrator routing and fallback chaining.
- [x] **Operational Runbook:** Documented troubleshooting for Cartesian Explosions and Expired Reference records.

## Usage Example (Surrogate Key Resolution)

```python
from src.reference_data.lookup_engine.lookup_manager import LookupManager

manager = LookupManager(logger)

# 1. Resolve a Customer Surrogate Key
fact_df = manager.resolve(
    df=raw_transactions_df,
    resolver_type="SURROGATE_KEY",
    dim_df=dim_customer,
    natural_key="shopify_customer_id",
    surrogate_key="CUSTOMER_SK",
    transaction_date_col="order_date",
    default_fallback=-1
)
```
