# Interview Notes: Dimension Layer

## Q: What is a conformed dimension?
**A:** "A conformed dimension is a dimension table that has the exact same meaning, grain, and structure regardless of which fact table it is joined to. For example, `dim_date` or `dim_store`. In an enterprise, if Finance and Marketing are both running reports, they MUST join against the same conformed `dim_date`. This ensures that 'Q3 Revenue' means the exact same thing to both departments, eliminating data silos."

## Q: Why separate Dimensions from Facts? (Why not One Big Table - OBT?)
**A:** "While OBT (One Big Table) is popular in modern columnar databases for simple reporting, Kimball Star Schemas (separating Facts and Dimensions) remain superior for complex enterprise BI. 
1. **Maintainability:** If a customer changes their address, in a Star Schema I update one row in `dim_customer`. In an OBT, I have to run an expensive `UPDATE` on 5,000 historical rows in the massive fact table.
2. **SCD Type 2:** Dimensional modeling natively supports tracking historical changes (SCD2). OBT struggles immensely with historical state representation without blowing up storage."

## Q: How do you model SCD Type 2?
**A:** "Slowly Changing Dimensions Type 2 track historical changes. In our architecture, dbt handles this via `snapshots`. When a customer's segment changes from 'Active' to 'VIP', dbt invalidates the old record by setting `valid_to = current_timestamp` and `is_current = FALSE`, and inserts a new row with `is_current = TRUE`. Both rows share the same Business Key, but have different Surrogate Keys, allowing historical fact records to remain tied to the historical state of the customer."

## Enterprise Best Practices Demonstrated
1. **Explicit 'UNKNOWN' handling:** Coalescing Nulls to 'UNKNOWN' to prevent BI drill-down breaks.
2. **Audit Columns:** Adding `dbt_updated_at` to the final dimensions.
