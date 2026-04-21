# Interview Notes: Enterprise MERGE Processing

## "How did you handle Late Arriving Records in your CDC pipeline?"
**Answer:** A naive `MERGE` simply upserts whatever is in the stream. To handle out-of-order, late-arriving payloads in our distributed architecture, I enforced a strict timestamp validation check directly within the `WHEN MATCHED` clause: `AND src.source_updated_at > tgt.source_updated_at`. If an older record arrives *after* we've already processed a newer record, the `MERGE` safely ignores it.

## "Why use MD5 Checksums instead of comparing every column during the MERGE?"
**Answer:** Comparing 50 individual columns in a `WHEN MATCHED` clause is incredibly difficult to maintain and computationally expensive to evaluate. By generating a single `MD5()` hash of all descriptive columns during the `QUALIFY` step, I only need to check `tgt.record_checksum != src.record_checksum`. This handles schema drift elegantly and reduces the SQL complexity of the SCD Type 2 stored procedures.

### How MD5 drives the SCD2 Mechanism (Code Example)
In a Slowly Changing Dimension (SCD2), we only want to create a new version of a row if the data *actually changed*. If the upstream system sends a duplicate payload where no values changed, we want to ignore it. 

**Without MD5 (Terrible Maintenance):**
```sql
WHEN MATCHED 
  AND (tgt.first_name != src.first_name 
       OR tgt.last_name != src.last_name 
       OR tgt.email != src.email 
       -- ... 47 more columns)
THEN UPDATE SET is_current = FALSE;
```

**With MD5 (The Enterprise Mechanism):**
```sql
-- Step 1: Generate the checksum in the source CTE.
-- You concatenate ALL descriptive columns in the table (all 50 of them), not just three!
MD5(
  NVL(first_name,'') || 
  NVL(last_name,'') || 
  NVL(email,'') || 
  NVL(phone_number,'') ||
  NVL(address,'')
  -- ... include EVERY column you want to track for SCD2 changes
) AS record_checksum

-- Step 2: Use it in the MERGE
WHEN MATCHED 
  AND tgt.is_current = TRUE 
  AND tgt.record_checksum != src.record_checksum  -- <== The SCD2 Trigger!
THEN UPDATE SET 
  tgt.is_current = FALSE, 
  tgt.valid_to = CURRENT_TIMESTAMP();
```
*Note for Interview:* Be sure to mention that you wrap the concatenated columns in `NVL()` or `COALESCE()` before hashing, because concatenating a `NULL` value in Snowflake results in a `NULL` hash, which breaks the comparison.

## "How do you guarantee Idempotency if the pipeline fails?"
**Answer:** Idempotency means the operation can be applied multiple times without changing the result beyond the initial application. By using Snowflake Streams, we ensure the offset only advances on a successful `COMMIT`. If a Task fails mid-flight, the transaction rolls back, and the exact same stream data will be processed on the next run. Because our `MERGE` checks the `CHECKSUM` and `UPDATED_AT` timestamps, a duplicate run will simply result in 0 rows updated, guaranteeing perfect consistency in the target layer.

## "In your pipeline, what is the difference between merging a Dimension (SCD2) and merging Transactional data (like Orders)?"
**Answer:** This is a crucial distinction in Data Modeling. 

**Dimensions (SCD Type 2):** When a Customer's data changes, we want to keep the historical record. We retire the old row (`is_current = FALSE`) and insert a brand new row. This is because we need to know what address the customer lived at *when they made a past purchase*.

**Transactional Data (Orders Fact):** When an Order's data changes (e.g., Status changes from `PENDING` to `SHIPPED` to `DELIVERED`), we do **NOT** create new historical rows. Fact tables hold billions of rows; creating a new row for every state change would cause the table size to explode. 
Instead, we perform a **Transactional Merge**. We simply find the existing Order ID and `UPDATE` it in place to reflect the current state.

**The Golden Rule of Transactional Merges:**
Because we are updating in-place, we must protect against "Late Arriving Data". If a `SHIPPED` event arrives *before* a delayed `PENDING` event, we don't want the delayed `PENDING` event to accidentally overwrite the `SHIPPED` status. 
We solve this by strictly enforcing timestamp validation in the `MERGE`:
```sql
WHEN MATCHED 
  AND src.source_updated_at > tgt.source_updated_at  -- <== Protects against late data!
THEN UPDATE SET status = src.status
```
If an older record arrives late, the `MERGE` safely ignores it.

## "Wait, a Transactional Merge just updates the row in place. Isn't that exactly the same as an SCD Type 1?"
**Answer:** Technically, yes—they both `UPDATE` rows in place instead of creating history. But architecturally, they are entirely different patterns used for different data types.

**Difference 1: The Data Type (Entities vs Events)**
* **SCD1** is used for *Reference Data* (like Currency Conversion Rates or Store Locations). This is small, slow-moving data.
* **Transactional Merges** are used for *Fact/Event Data* (like Orders or Payments). This is massive, high-velocity data representing a specific point-in-time event. 

**Difference 2: The Update Logic (Blind Overwrite vs State Progression)**
* **SCD1 (Blind Overwrite):** In an SCD1 (like updating a Currency Rate), we generally trust the source system to just provide the "absolute current truth". If the rate changes from 1.5 to 1.6, we just blindly overwrite it. 
* **Transactional Merge (State Progression):** Because Orders are high-velocity events traveling through distributed message queues (like Kafka or Snowpipe), messages frequently arrive out of order. A Transactional Merge **never** blindly overwrites data. It enforces strict *State Progression* by validating timestamps (`AND src.source_updated_at > tgt.source_updated_at`) to ensure an older state (PENDING) doesn't accidentally overwrite a newer state (SHIPPED).
