# Phase 09 - Module 6: Enterprise JSON Processing Framework

This module implements the ingestion layer for parsing deeply nested, semi-structured JSON payloads natively in Snowflake using Snowpark.

## Deliverables Checklist

- [x] **Design Summary:** Documented the strategy for using `VARIANT` and Snowpark's DataFrame API over raw SQL.
- [x] **Repository Structure:** Created `json_processing/` with `parsers`, `flatten`, and `schema` subdirectories.
- [x] **JSON Parser:** Implemented `JSONParser` to dynamically extract scalar values using dot-notation maps, replacing verbose `GET_PATH` SQL.
- [x] **Array Flattener:** Implemented `ArrayFlattener` to perform targeted `LATERAL FLATTEN` table functions on nested arrays.
- [x] **Schema Evolution:** Implemented `SchemaDetector` to handle upstream API version upgrades by dynamically merging extraction maps.
- [x] **Unit Tests:** `test_json_processing.py` validates the schema override logic.
- [x] **Operational Runbook:** Documented troubleshooting for memory errors (large payloads) and Cartesian explosions (nested flattens).

## Usage Example (Extract & Flatten)

```python
from src.json_processing.parsers.json_parser import JSONParser
from src.json_processing.flatten.flattener import ArrayFlattener
from snowflake.snowpark.types import StringType, FloatType

extraction_map = {
    "ORDER_ID": {"path": "order.id", "type": StringType()},
    "CUSTOMER_EMAIL": {"path": "customer.email", "type": StringType()},
    "ORDER_TOTAL": {"path": "payment.total", "type": FloatType()}
}

# Extract scalar fields
parser = JSONParser(logger)
extracted_df = parser.extract_fields(raw_df, "RAW_PAYLOAD", extraction_map)

# Flatten the line items array
flattener = ArrayFlattener(logger)
exploded_df = flattener.flatten_array(extracted_df, array_col="RAW_PAYLOAD", path="order.line_items")
```
