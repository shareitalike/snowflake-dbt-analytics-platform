# Interview Notes: Reference Data & Lookup Framework

## Q: How do you manage reference data?
**A:** "I treat reference data as a Slowly Changing Dimension (SCD) by default. In retail, categorizations, taxes, and regions change over time. Using a standard static lookup table corrupts historical data during replays. Instead, our framework enforces temporal bounds, ensuring the lookup is historically accurate to the transaction date."

## Q: How do you resolve surrogate keys?
**A:** "I use a `SurrogateKeyResolver` that performs a distributed left join against the dimension table, matching on the natural Business Key *and* bounded by the `effective_start_date` and `effective_end_date`. If a match is found, the integer Surrogate Key is appended to the fact table. If not, we assign a default fallback key (e.g., `-1` for UNMAPPED) to preserve referential integrity."

## Q: How do you handle missing lookup values?
**A:** "The cardinal rule of data engineering in retail is: *never drop a revenue transaction just because a lookup code is missing*. If the `LookupManager` cannot find a match, it falls back to a standardized default value. Concurrently, it flags a Data Quality warning in the audit metadata, triggering an alert for the Master Data team to fix the reference table asynchronously."

## Q: How do you cache frequently used reference data?
**A:** "For very small reference domains—like Currency Codes or Payment Methods—doing a distributed join incurs a huge network shuffle penalty. I built a `ReferenceCache` in Snowpark. It pulls the small reference table into a local Python dictionary via `.collect()` and broadcasts it to the worker nodes. This allows the lookup to happen instantly in-memory."

## Enterprise Best Practices Demonstrated
1. **Dimension Pruning:** We only cache tables under a strict row limit (e.g., 100,000) to prevent OOM errors.
2. **Resilient Architecture:** We prioritize pipeline throughput and data retention over strict relational purity by utilizing fallbacks.
3. **Temporal Immutability:** Bounded joins guarantee that replaying 2024 data in 2026 yields identical analytical results.
