-- Step 7: Mart - Create company hiring mart (dimensional mart)
-- Run after Step 6
-- Who is hiring, for which roles, where and when. Useful for prospecting companies
-- to apply to

DROP SCHEMA IF EXISTS company_mart CASCADE;

CREATE SCHEMA company_mart;

-- Note on surrogate keys:
-- The ids below are generated with ROW_NUMBER() over a sorted DISTINCT list.
-- A self-join counting "how many values sort before me" also works, but it is O(n^2):
-- job_title has ~458K distinct values, which is ~10^11 comparisons. ROW_NUMBER() is a
-- single sort, so this whole script runs in seconds.

-- 1. Company dimension
CREATE TABLE company_mart.dim_company (
    company_id      INTEGER     PRIMARY KEY,
    company_name    VARCHAR
);

INSERT INTO company_mart.dim_company
SELECT company_id, name AS company_name
FROM company_dim;

-- 2. Job title short dimension (10 standardised roles)
CREATE TABLE company_mart.dim_job_title_short (
    job_title_short_id  INTEGER     PRIMARY KEY,
    job_title_short     VARCHAR     UNIQUE
);

INSERT INTO company_mart.dim_job_title_short
SELECT
    ROW_NUMBER() OVER (ORDER BY job_title_short) AS job_title_short_id,
    job_title_short
FROM (
    SELECT DISTINCT job_title_short
    FROM job_postings_fact
    WHERE job_title_short IS NOT NULL
);

-- 3. Job title dimension (raw titles as posted)
CREATE TABLE company_mart.dim_job_title (
    job_title_id    INTEGER     PRIMARY KEY,
    job_title       VARCHAR
);

INSERT INTO company_mart.dim_job_title
SELECT
    ROW_NUMBER() OVER (ORDER BY job_title) AS job_title_id,
    job_title
FROM (
    SELECT DISTINCT job_title
    FROM job_postings_fact
    WHERE job_title IS NOT NULL
);

-- 4. Location dimension (country + location combinations)
CREATE TABLE company_mart.dim_location (
    location_id     INTEGER     PRIMARY KEY,
    job_country     VARCHAR,
    job_location    VARCHAR
);

INSERT INTO company_mart.dim_location
SELECT
    ROW_NUMBER() OVER (ORDER BY job_country, job_location) AS location_id,
    job_country,
    job_location
FROM (
    SELECT DISTINCT job_country, job_location
    FROM job_postings_fact
    WHERE job_country IS NOT NULL
        AND job_location IS NOT NULL
);

-- 5. Month level date dimension
CREATE TABLE company_mart.dim_date_month (
    month_start_date    DATE        PRIMARY KEY,
    year                INTEGER,
    month               INTEGER
);

INSERT INTO company_mart.dim_date_month
SELECT DISTINCT
    DATE_TRUNC('month', job_posted_date)::DATE AS month_start_date,
    YEAR(job_posted_date) AS year,
    MONTH(job_posted_date) AS month
FROM job_postings_fact
WHERE job_posted_date IS NOT NULL;

-- 6. Bridge: company <-> location (many-to-many, a company hires in many places)
CREATE TABLE company_mart.bridge_company_location (
    company_id      INTEGER,
    location_id     INTEGER,
    PRIMARY KEY (company_id, location_id),
    FOREIGN KEY (company_id) REFERENCES company_mart.dim_company(company_id),
    FOREIGN KEY (location_id) REFERENCES company_mart.dim_location(location_id)
);

INSERT INTO company_mart.bridge_company_location
SELECT DISTINCT
    jpf.company_id,
    loc.location_id
FROM job_postings_fact AS jpf
INNER JOIN company_mart.dim_location AS loc
    ON jpf.job_country = loc.job_country
    AND jpf.job_location = loc.job_location
WHERE jpf.company_id IS NOT NULL;

-- 7. Bridge: job title short <-> job title (which raw titles roll up to each role)
CREATE TABLE company_mart.bridge_job_title (
    job_title_short_id  INTEGER,
    job_title_id        INTEGER,
    PRIMARY KEY (job_title_short_id, job_title_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.dim_job_title_short(job_title_short_id),
    FOREIGN KEY (job_title_id) REFERENCES company_mart.dim_job_title(job_title_id)
);

INSERT INTO company_mart.bridge_job_title
SELECT DISTINCT
    djs.job_title_short_id,
    djt.job_title_id
FROM job_postings_fact AS jpf
INNER JOIN company_mart.dim_job_title_short AS djs
    ON jpf.job_title_short = djs.job_title_short
INNER JOIN company_mart.dim_job_title AS djt
    ON jpf.job_title = djt.job_title;

-- 8. Fact table
-- Grain: one row per company_id + job_title_short_id + job_country + month_start_date
-- Counts are additive. Median/min/max salary are NOT additive - recompute from the
-- warehouse (or flat mart) if you need them at a coarser grain
CREATE TABLE company_mart.fact_company_hiring_monthly (
    company_id                      INTEGER,
    job_title_short_id              INTEGER,
    job_country                     VARCHAR,
    month_start_date                DATE,
    postings_count                  INTEGER,
    remote_postings_count           INTEGER,
    health_insurance_postings_count INTEGER,
    no_degree_mention_count         INTEGER,
    salary_postings_count           INTEGER,
    median_salary_year              DOUBLE,
    min_salary_year                 DOUBLE,
    max_salary_year                 DOUBLE,
    PRIMARY KEY (company_id, job_title_short_id, job_country, month_start_date),
    FOREIGN KEY (company_id) REFERENCES company_mart.dim_company(company_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.dim_job_title_short(job_title_short_id),
    FOREIGN KEY (month_start_date) REFERENCES company_mart.dim_date_month(month_start_date)
);

INSERT INTO company_mart.fact_company_hiring_monthly
SELECT
    jpf.company_id,
    djs.job_title_short_id,
    jpf.job_country,
    DATE_TRUNC('month', jpf.job_posted_date)::DATE AS month_start_date,
    COUNT(*)                                        AS postings_count,
    COUNT(*) FILTER (WHERE jpf.job_work_from_home)  AS remote_postings_count,
    COUNT(*) FILTER (WHERE jpf.job_health_insurance) AS health_insurance_postings_count,
    COUNT(*) FILTER (WHERE jpf.job_no_degree_mention) AS no_degree_mention_count,
    COUNT(jpf.salary_year_avg)                      AS salary_postings_count,
    MEDIAN(jpf.salary_year_avg)                     AS median_salary_year,
    MIN(jpf.salary_year_avg)                        AS min_salary_year,
    MAX(jpf.salary_year_avg)                        AS max_salary_year
FROM job_postings_fact AS jpf
INNER JOIN company_mart.dim_job_title_short AS djs
    ON jpf.job_title_short = djs.job_title_short
WHERE jpf.company_id IS NOT NULL
    AND jpf.job_posted_date IS NOT NULL
    AND jpf.job_country IS NOT NULL
GROUP BY ALL;

-- Verify
SELECT 'Company Dimension' AS table_name, COUNT(*) AS record_count FROM company_mart.dim_company
UNION ALL
SELECT 'Job Title Short Dimension', COUNT(*) FROM company_mart.dim_job_title_short
UNION ALL
SELECT 'Job Title Dimension', COUNT(*) FROM company_mart.dim_job_title
UNION ALL
SELECT 'Location Dimension', COUNT(*) FROM company_mart.dim_location
UNION ALL
SELECT 'Date Month Dimension', COUNT(*) FROM company_mart.dim_date_month
UNION ALL
SELECT 'Company Location Bridge', COUNT(*) FROM company_mart.bridge_company_location
UNION ALL
SELECT 'Job Title Bridge', COUNT(*) FROM company_mart.bridge_job_title
UNION ALL
SELECT 'Company Hiring Fact', COUNT(*) FROM company_mart.fact_company_hiring_monthly;

SELECT '=== Job Title Variations for Data Engineer (sample) ===' AS info;
SELECT djt.job_title
FROM company_mart.bridge_job_title AS b
JOIN company_mart.dim_job_title_short AS djs ON b.job_title_short_id = djs.job_title_short_id
JOIN company_mart.dim_job_title AS djt ON b.job_title_id = djt.job_title_id
WHERE djs.job_title_short = 'Data Engineer'
ORDER BY HASH(djt.job_title)  -- deterministic "random" pick
LIMIT 8;

SELECT '=== Top 10 Companies Hiring Data Engineers ===' AS info;
SELECT
    dc.company_name,
    SUM(f.postings_count) AS postings,
    COUNT(DISTINCT f.job_country) AS countries,
    ROUND(100.0 * SUM(f.remote_postings_count) / SUM(f.postings_count), 1) AS remote_pct
FROM company_mart.fact_company_hiring_monthly AS f
JOIN company_mart.dim_company AS dc ON f.company_id = dc.company_id
JOIN company_mart.dim_job_title_short AS djs ON f.job_title_short_id = djs.job_title_short_id
WHERE djs.job_title_short = 'Data Engineer'
GROUP BY dc.company_name
ORDER BY postings DESC
LIMIT 10;
