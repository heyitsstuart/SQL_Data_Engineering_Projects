-- Master build script for the data warehouse + marts pipeline
-- Runs every step in order. Every step is idempotent, so the whole build can be re-run.
--
-- Usage (run from inside the 2_DW_Mart_Build folder so the .read paths resolve):
--   duckdb dw_marts.duckdb -c ".read build_dw_marts.sql"
--
-- Usage (MotherDuck):
--   export MOTHERDUCK_TOKEN=...   then
--   duckdb "md:dw_marts" -c ".read build_dw_marts.sql"
--
-- The database file is created if it doesn't exist.

.bail on
.timer on

-- Step 1: DW - Create star schema tables
.read 01_create_tables_dw.sql

-- Step 2: DW - Load data from CSV files (Google Cloud Storage) into the star schema
.read 02_load_schema_dw.sql

-- Step 3: Mart - Flat mart (denormalized job postings)
.read 03_create_flat_mart.sql

-- Step 4: Mart - Skills demand mart (monthly time series)
.read 04_create_skills_mart.sql

-- Step 5: Mart - Priority roles mart (snapshot)
.read 05_create_priority_mart.sql

-- Step 6: Mart - Incremental update of the priority mart (MERGE)
.read 06_update_priority_mart.sql

-- Step 7: Mart - Company hiring mart
.read 07_create_company_mart.sql

-- Step 8: Data quality checks across all layers
.read 08_data_quality_checks.sql

SELECT '=== Pipeline Build Complete ===' AS status;
