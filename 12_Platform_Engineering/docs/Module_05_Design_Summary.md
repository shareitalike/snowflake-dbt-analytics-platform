# Enterprise Security & Governance Framework
## Module 05 - Design Summary

### Zero Trust & Network Policies
In our environment, nobody has default access to Snowflake. Our `network_policies.sql` implements a strict IP Allowlist. Only the corporate VPN and the AWS NAT Gateway (used by Airflow) are permitted to reach the Snowflake login endpoint. Everything else is implicitly blocked (`0.0.0.0/0`).

### Advanced Data Protection (Masking & Row Access)
To meet Enterprise Compliance (GDPR/CCPA), we utilize Snowflake's advanced governance features:
1. **Dynamic Data Masking:** Deployed via Terraform (`masking/main.tf`), we mask PII (Emails, SSNs) at runtime. The data remains raw on disk, but if an Analyst queries it, Snowflake dynamically obfuscates it (`*****@gmail.com`). Only the `PII_ADMIN_ROLE` sees the raw values.
2. **Tag-Based Masking:** We implemented Object Tags (`PII_DATA`). Rather than applying masking policies column by column, we assign the masking policy to the tag. Any column tagged with `PII_DATA` is instantly protected.
3. **Row Access Policies:** Deployed via Terraform, we enforce multi-tenant isolation. A European Sales Manager querying the `FCT_SALES` table will mathematically only see rows where `REGION = 'EU'`, even though it is the exact same table the US Manager is querying.

### Time Travel and Fail-Safe Governance
We enforce a strict 90-day Time Travel retention policy on the Bronze and Silver databases, allowing us to undrop tables or query historical states in the event of an accidental deletion. For Gold, since it is 100% reproducible via dbt Cloud, Time Travel is set to 1 day to save on storage costs. Fail-safe (7 days) provides absolute disaster recovery via Snowflake Support.
