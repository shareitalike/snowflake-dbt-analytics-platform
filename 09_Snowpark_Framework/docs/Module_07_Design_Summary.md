# Enterprise Reference Data & Lookup Framework
## Module 07 - Design Summary

### Master Data vs Reference Data
**Master Data** represents the core business entities (Customers, Products, Stores) that drive transactions. These are highly dynamic and volumetrically massive.
**Reference Data** categorizes those entities (e.g., Country Codes, Tax Rates, Payment Methods). Reference Data is smaller, heavily standardized, but changes slowly over time (e.g., tax rate increases for a region). Our framework explicitly supports 10 core domains: Country, Currency, Store, Region, Customer Segment, Product Category, Supplier, Promotion, Tax, and Payment Method.

### Lookup Strategy & Effective Dating
Because Reference Data is Slowly Changing, naive `JOIN ON ID = ID` strategies result in data corruption when historical transactions are replayed. The `LookupManager` leverages the `DimensionResolver` to perform **bounded temporal joins** (`transaction.date >= reference.start_date AND transaction.date < reference.end_date`). This enforces historical immutability. 
It supports multiple resolutions:
- **Surrogate Key Resolution:** Replacing natural business keys (like a String Shopify Product ID) with a `BIGINT` Snowflake Surrogate Key.
- **Hierarchy Resolution:** Resolving parent/child relationships (e.g. mapping a Store to a Region, and a Region to a Country).

### Caching Strategy
For small, high-throughput domains (e.g. Currency Codes or Payment Methods), distributed joins trigger unnecessary micro-partition scans and network shuffles. The `ReferenceCache` class pulls these tiny lookup tables into a Python dictionary, broadcasting them to Snowpark worker nodes, executing the lookup entirely in memory.

### Fallback Strategy
A missing reference key (e.g. a new Payment Method introduced in Shopify) must NEVER drop a transaction. Dropping revenue transactions breaks financial reconciliation. The framework assigns a `DEFAULT_UNMAPPED` value and injects a DQ warning for data stewards.
