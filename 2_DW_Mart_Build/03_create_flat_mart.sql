-- Step 3: Mart - Create flat mart (denormalized job postings table)
-- Run after Step 2
-- One row per job posting with company name and skills joined in, so ad-hoc
-- questions can be answered without writing the 3-table join every time

-- Drop the schema first so the script can be re-run (idempotency)
DROP SCHEMA IF EXISTS flat_mart CASCADE;

CREATE SCHEMA flat_mart;

CREATE TABLE flat_mart.job_postings (
    -- fact table fields
    job_id                  INTEGER     PRIMARY KEY,
    job_title_short         VARCHAR,
    job_title               VARCHAR,
    job_location            VARCHAR,
    job_via                 VARCHAR,
    job_schedule_type       VARCHAR,
    job_work_from_home      BOOLEAN,
    search_location         VARCHAR,
    job_posted_date         TIMESTAMP,
    job_no_degree_mention   BOOLEAN,
    job_health_insurance    BOOLEAN,
    job_country             VARCHAR,
    salary_rate             VARCHAR,
    salary_year_avg         DOUBLE,
    salary_hour_avg         DOUBLE,
    -- company dimension fields
    company_id              INTEGER,
    company_name            VARCHAR,
    -- skills collapsed into a list of (type, name) structs
    skill_count             INTEGER,
    skills_and_types        STRUCT(type VARCHAR, name VARCHAR)[]
);

-- Performance notes (~5 min -> ~25 sec on my laptop):
--   1. Aggregate skills per job_id first, then join to the fact table, instead of
--      joining everything and doing GROUP BY on all 17 wide fact columns
--   2. LIST_SORT() each small list after aggregating rather than ARRAY_AGG(... ORDER BY ...)
--      which forces a much more expensive ordered aggregate (~170s vs ~9s)
INSERT INTO flat_mart.job_postings
WITH job_skills AS (
    SELECT
        sjd.job_id,
        COUNT(*) AS skill_count,
        -- sorted by type then name so every posting's list is in a consistent order
        LIST_SORT(ARRAY_AGG(STRUCT_PACK(type := sd.type, name := sd.skills))) AS skills_and_types
    FROM skills_job_dim AS sjd
    INNER JOIN skills_dim AS sd
        ON sjd.skill_id = sd.skill_id
    GROUP BY sjd.job_id
)
SELECT
    jpf.job_id,
    jpf.job_title_short,
    jpf.job_title,
    jpf.job_location,
    jpf.job_via,
    jpf.job_schedule_type,
    jpf.job_work_from_home,
    jpf.search_location,
    jpf.job_posted_date,
    jpf.job_no_degree_mention,
    jpf.job_health_insurance,
    jpf.job_country,
    jpf.salary_rate,
    jpf.salary_year_avg,
    jpf.salary_hour_avg,
    cd.company_id,
    cd.name AS company_name,
    -- ~285K postings have no skills: give them 0 and an empty list rather than NULL
    COALESCE(js.skill_count, 0) AS skill_count,
    COALESCE(js.skills_and_types, []) AS skills_and_types
FROM job_postings_fact AS jpf
LEFT JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id
LEFT JOIN job_skills AS js
    ON jpf.job_id = js.job_id;

-- Verify: flat mart should have exactly one row per fact row
SELECT 'Flat Mart Job Postings' AS table_name, COUNT(*) AS record_count FROM flat_mart.job_postings
UNION ALL
SELECT 'Job Postings Fact (source)', COUNT(*) FROM job_postings_fact;

SELECT '=== Flat Mart Sample ===' AS info;
SELECT
    job_id,
    company_name,
    job_title_short,
    job_country,
    salary_year_avg,
    job_work_from_home,
    skill_count,
    skills_and_types
FROM flat_mart.job_postings
WHERE salary_year_avg IS NOT NULL
LIMIT 10;
