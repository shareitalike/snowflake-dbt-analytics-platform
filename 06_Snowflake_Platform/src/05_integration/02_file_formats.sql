-- ==============================================================================
-- 02_file_formats.sql
-- Description: Standardized File Formats for Ingestion
-- ==============================================================================

USE ROLE ETL_ADMIN;
USE DATABASE DB_PROD_RAW;
-- Storing global formats in a utility schema (assumed creation)
CREATE SCHEMA IF NOT EXISTS SC_UTILITIES;
USE SCHEMA SC_UTILITIES;

-- 1. Standard JSON Format (Strips outer array if present)
CREATE FILE FORMAT IF NOT EXISTS FMT_JSON_STRIP_OUTER
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    IGNORE_UTF8_ERRORS = TRUE
    COMPRESSION = 'AUTO'
    COMMENT = 'Standard JSON format for API and Webhook payloads';

-- 2. Standard CSV Format (Skips Header)
CREATE FILE FORMAT IF NOT EXISTS FMT_CSV_SKIP_HEADER
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    COMPRESSION = 'AUTO'
    COMMENT = 'Standard CSV format for Oracle ERP and Vendor files';

-- 3. Standard Parquet Format
CREATE FILE FORMAT IF NOT EXISTS FMT_PARQUET_STANDARD
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
    COMMENT = 'Standard Parquet format for highly structured data drops';
