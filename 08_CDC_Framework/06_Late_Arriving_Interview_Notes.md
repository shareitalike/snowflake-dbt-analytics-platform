# Interview Notes: Enterprise Late Arriving Data

## "What happens if a Customer arrives after an Order?"
**Answer:** In a distributed event-driven architecture, this is extremely common. If we did nothing, the Order would either be dropped or fail downstream Foreign Key constraints. I solved this by implementing the **Inferred Member (Ghost Record)** pattern. Right before the Orders Task runs, a stored procedure scans the incoming stream. If it finds a `Customer_ID` that doesn't exist in our Dimension table, it proactively creates a "Ghost" Customer record with placeholder data (e.g., Name = 'UNKNOWN_LATE_ARRIVING'). The Order successfully attaches to this Ghost record. 

## "How do you preserve historical accuracy and handle the correction?"
**Answer:** Because we utilize an SCD Type 2 dimension structure, the correction is automatic. When the *actual* Customer payload eventually arrives via the CDC stream, our standard `MERGE` procedure treats it as an update. It expires the Ghost record (setting `is_current = FALSE` and applying a `valid_to` timestamp) and inserts the real Customer data as the new active version. Because downstream Kimball Fact tables link on the business key prior to the surrogate key mapping (which is handled later in dbt), the historical lineage is perfectly preserved.

## "How does this impact Performance and the Watermark framework?"
**Answer:** It completely decouples pipeline dependencies. The Watermark doesn't have to pause and wait for missing data (which would halt the entire enterprise pipeline). The CDC tasks process whatever data they have as fast as possible. The Ghost inference logic uses `WHERE ... NOT IN (SELECT ...)` which is highly optimized via Snowflake's micro-partition pruning. We get sub-minute latency without sacrificing referential integrity.
