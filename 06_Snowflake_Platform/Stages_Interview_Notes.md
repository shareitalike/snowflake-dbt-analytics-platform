# Interview Notes: Snowflake Stages (Internal vs External)

In Snowflake, a **Stage** is simply a location that holds data files (like CSV, JSON, Parquet) so they can be loaded into Snowflake tables (or unloaded from them). 

While most Enterprise architectures heavily rely on **External Stages** (pointing to AWS S3, Azure Blob, or GCS), Snowflake also provides native **Internal Stages** where Snowflake itself physically manages the storage.

---

## 1. External Stages
**What it is:** A pointer to an external cloud storage bucket that your company owns and manages (e.g., AWS S3).
**Production Scenario:** In our architecture, the `STG_SHOPIFY_RAW` external stage points to our S3 bucket. We use an external stage because other company applications (like AWS Lambda or external data science tools) also need direct access to those raw files.
```sql
-- Creating an External Stage
CREATE OR REPLACE STAGE STG_SHOPIFY_RAW
  URL = 's3://omni-retail-prod-raw/shopify/'
  STORAGE_INTEGRATION = S3_PROD_INTEGRATION;
```

---

## 2. Internal Stages (Three Types)
If you don't want to manage an AWS S3 bucket, Snowflake can store the files for you using Internal Stages. You upload files to them using the `PUT` command (via SnowSQL or Python), and load them using the `COPY INTO` command. There are three distinct types:

### A. User Stages (`@~`)
**What it is:** Every single user in Snowflake automatically gets their own personal internal stage. It is referenced using the tilde `~`.
**Production Scenario:** A Data Analyst wants to quickly upload a local 5MB CSV file from their laptop containing custom mapping rules to test a query. They don't want to bother the Data Engineering team to put it in S3.
**Rules:** Cannot be dropped, cannot be shared with other users.
```sql
-- Uploading a local file to the user's personal stage (Run in SnowSQL/Python)
PUT file:///tmp/custom_mapping.csv @~;

-- Loading from the User Stage
COPY INTO TB_MAPPING_TEST
FROM @~/custom_mapping.csv.gz;
```

### B. Table Stages (`@%table_name`)
**What it is:** Every single table in Snowflake automatically has an internal stage attached to it. It is referenced using the `%` sign. 
**Production Scenario:** A downstream application exports a daily batch of `POS_TRANSACTIONS.csv` that will *only* ever be loaded into the `TB_POS_TRANSACTIONS` table. To keep things clean, the application uploads the file directly to the table's dedicated stage.
**Rules:** Cannot be dropped (unless the table is dropped), cannot be shared across multiple tables.
```sql
-- Uploading a file directly to the Table's specific stage
PUT file:///tmp/pos_transactions.csv @%TB_POS_TRANSACTIONS;

-- Loading from the Table Stage
COPY INTO TB_POS_TRANSACTIONS
FROM @%TB_POS_TRANSACTIONS;
```

### C. Named Internal Stages (`@stage_name`)
**What it is:** A custom-created internal stage. This is the **most common internal stage** used in production. It acts like a secure, managed FTP folder inside Snowflake.
**Production Scenario:** You are deploying a Snowpark Python framework (like in our `09_Snowpark_Framework` module). You need a central, secure place to upload the Python `.zip` packages and `.toml` configuration files so that multiple Snowflake Stored Procedures can access them. 
**Rules:** Must be explicitly created (`CREATE STAGE`). Can be secured with RBAC roles and shared across multiple users and tables.
```sql
-- Creating a Named Internal Stage
CREATE OR REPLACE STAGE STG_SNOWPARK_ARTIFACTS
  DIRECTORY = (ENABLE = TRUE);

-- Uploading Python code to the named stage
PUT file:///app/build/my_python_code.zip @STG_SNOWPARK_ARTIFACTS/code/;

-- Loading data from the named stage into multiple tables
COPY INTO TB_RAW_APP_LOGS FROM @STG_SNOWPARK_ARTIFACTS/logs/;
```

---

## 🛑 Interview Questions

### "Why would you choose an External Stage over an Internal Stage?"
**Answer:** "We use External Stages (like AWS S3) for our Bronze ingestion layer because it decouples our storage from our compute platform. If our Data Science team wants to run Apache Spark against the raw JSON files, or if our Archival team wants to push old files to AWS Glacier for cheap long-term storage, they can access the S3 bucket directly without ever waking up Snowflake or needing Snowflake credentials."

### "When is a Named Internal Stage better than a Table Stage?"
**Answer:** "A Table Stage (`@%table_name`) is tightly coupled to a single table. If I upload a file there, I can't easily load that same file into a different table. A **Named Internal Stage** is decoupled and flexible. It allows multiple users, roles, and procedures to access the same directory of files securely using standard Snowflake Role-Based Access Control (RBAC). In fact, we rely on Named Internal Stages to host all of our Python UDFs and Snowpark packages!"

### "In your Named Internal Stage, why did you add `DIRECTORY = (ENABLE = TRUE)`?"
**Answer:** "By default, a Snowflake stage is just a dumb storage bucket. By enabling **Directory Tables**, Snowflake overlays a SQL-queryable metadata table on top of the stage. 
Instead of just using the basic `LIST` command, I can write actual SQL against the stage: `SELECT * FROM DIRECTORY(@STG_SNOWPARK_ARTIFACTS);`. This allows my pipelines to dynamically query file sizes, last modified dates, and MD5 hashes, or even generate Pre-Signed URLs to securely download files (like PDF receipts or Snowpark `.zip` packages) directly from a dashboard. It is a mandatory best practice for Unstructured Data and Snowpark architectures."

### "If files are stored in a User Stage (`@~`) or Table Stage (`@%table_name`), how do you check what's inside them?"
**Answer:** "Because User and Table stages do not support Directory Tables, you cannot query them using `SELECT`. You are strictly limited to using the `LIST` command.
* To view my personal files: `LIST @~;`
* To view a table's files: `LIST @%TB_POS_TRANSACTIONS;`
**The Significance:** This proves why Named Internal Stages with Directory Tables are vastly superior for production. User and Table stages are strictly for ad-hoc, manual developer tasks (like uploading a local CSV to test a query). You cannot build automated, dynamic file-scanning pipelines on top of them because you can't run standard SQL `SELECT` queries against their metadata."
