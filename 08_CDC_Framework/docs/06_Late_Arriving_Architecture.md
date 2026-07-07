# Module 6: Enterprise Late Arriving Data Architecture

## 1. Design Summary

### What are Late Arriving Records?
Late Arriving Records occur when data payloads are processed out of chronological order compared to the real-world business events they represent. 
* **Out-of-Order Updates:** An update to an order status arrives before the creation of the order itself.
* **Early Facts (Late Dimensions):** A Sales transaction arrives in the data platform, but the Customer or Product dimension associated with that sale has not yet been processed.

### Why they occur
In the OmniRetail Group architecture, source systems are distributed (Shopify, Oracle, POS). Network latency, varied batch windows, API retries, and asynchronous message queues (AWS SNS/SQS) guarantee that strict chronological ordering cannot be relied upon at the ingestion layer.

### Business Impact
If unhandled, late arriving data causes:
1. **Referential Integrity Failures:** Orders are dropped or error out because the `Customer_ID` does not exist in `TB_CUSTOMER_DIM`.
2. **Historical Inaccuracy:** An out-of-order SCD2 update might accidentally overwrite the "current" active record with stale data.
3. **Data Loss:** Streams might discard facts that fail validation.

### Detection & Correction Strategy
* **Out-of-Order Updates (MERGE Integration):** Solved in Module 4. We explicitly check `incoming.updated_at > existing.updated_at` within the `MERGE` to prevent stale data from overwriting newer data.
* **Early Facts (Ghost Dimension Integration):** If an Order arrives before the Customer, we inject a "Ghost" or "Inferred Member" into the Dimension table. This allows the Fact to be recorded successfully. When the Customer data finally arrives, the MERGE updates the Ghost record with the true attributes.

## 2. Folder Structure
```text
08_CDC_Framework/
├── 06_Late_Arriving_Architecture.md
├── src/
│   └── 13_late_arriving_procedures.sql   # Ghost dimension and reconciliation logic
├── tests/
│   └── 05_late_arriving_tests.sql        # Test cases for out-of-order and ghost records
├── 06_Late_Arriving_README.md
├── 06_Late_Arriving_Runbook.md
```

## 3. Fact & Dimension Reconciliation Strategy
* **Fact Reconciliation:** Facts are inherently immutable events. If a Fact arrives late (e.g., an offline POS syncs a day late), the `MERGE` simply inserts it. Because the `MERGE` is idempotent, duplicate late arrivals are ignored.
* **Dimension Reconciliation (SCD2 Correction):** When the true dimension payload arrives to overwrite a Ghost Record, the `MERGE` performs a standard SCD2 update. The Ghost record is expired, and the new record becomes the active version. Because downstream Fact tables link via the natural business key (prior to dbt surrogate key mapping), the facts immediately associate with the newly populated dimension data.

## 4. Watermark Integration
The Watermark Framework (Module 5) does not wait for missing data. It advances based on what was successfully processed in the current batch. Late arriving data simply gets picked up in whatever future batch it physically lands in, where it will be treated as a net-new incoming payload by the MERGE.
