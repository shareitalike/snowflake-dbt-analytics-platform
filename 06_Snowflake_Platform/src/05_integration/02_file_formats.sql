/* ==============================================================================
 * FILE: 02_file_formats.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Defines standardized file formats for data ingestion within the Bronze layer utility schema.
 * DESIGN DECISIONS: Configures JSON formats to strip outer arrays and ignore UTF-8 errors, and CSV formats to skip headers and handle empty strings as NULLs. Parquet uses Snappy compression.
 * WHY: Centralizing file formats ensures ingestion pipelines don't silently fail due to inconsistent source file structures. Stripping the outer array for JSON allows Snowflake to load the array elements as individual rows (NDJSON behavior).
 * ============================================================================== */

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

-- 2. Standard CSV Format (With Header Parsing for Schema Evolution)
CREATE FILE FORMAT IF NOT EXISTS FMT_CSV_WITH_HEADER
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    PARSE_HEADER = TRUE
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    COMPRESSION = 'AUTO'
    COMMENT = 'Standard CSV format with parse header for MATCH_BY_COLUMN_NAME';

-- 3. Standard Parquet Format
CREATE FILE FORMAT IF NOT EXISTS FMT_PARQUET_STANDARD
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
    COMMENT = 'Standard Parquet format for highly structured data drops';
