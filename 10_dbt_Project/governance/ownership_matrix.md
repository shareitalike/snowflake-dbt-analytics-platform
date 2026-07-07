# Enterprise Business Ownership Matrix

To ensure clear accountability for Data Quality and Data Catalog definitions, ownership is federated across business domains.

| Domain | Sub-Domain | Data Owner (Business) | Engineering Owner (Technical) | Primary Gold Models |
| :--- | :--- | :--- | :--- | :--- |
| **Sales** | eCommerce | VP of eCommerce | `@analytics_eng_sales` | `fct_sales`, `fct_orders` |
| **Finance** | Revenue & Payments | CFO | `@analytics_eng_fin` | `fct_payments`, `fct_sales` |
| **Inventory** | Supply Chain | Director of Operations | `@data_eng_sc` | `fct_inventory`, `dim_product` |
| **Marketing** | Campaigns & Cust | VP of Marketing | `@analytics_eng_mktg` | `fct_promotions`, `dim_customer` |
| **Support** | Customer Service | Head of CX | `@analytics_eng_cx` | `fct_returns`, `fct_support_tickets`|

*Rule:* Any schema change to a Primary Gold Model requires a Pull Request approval from the Technical Owner, who must verify alignment with the Business Owner.
