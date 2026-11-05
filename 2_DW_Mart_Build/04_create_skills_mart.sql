-- Step 4: Mart - Create skills demand mart (dimensional mart)
-- Run after Step 3
-- Tracks skill demand month by month. All measures are additive counts so they
-- can be safely rolled up to quarter / year / skill type without double counting

DROP SCHEMA IF EXISTS skills_mart CASCADE;

CREATE SCHEMA skills_mart;

-- 1. Skill dimension
CREATE TABLE skills_mart.dim_skill (
    skill_id    INTEGER     PRIMARY KEY,
    skills      VARCHAR,
    type        VARCHAR
);

INSERT INTO skills_mart.dim_skill (skill_id, skills, type)
SELECT skill_id, skills, type
FROM skills_dim;

-- 2. Month level date dimension
CREATE TABLE skills_mart.dim_date_month (
    month_start_date    DATE        PRIMARY KEY,
    year                INTEGER,
    month               INTEGER,
    month_name          VARCHAR,
    quarter             INTEGER,
    quarter_name        VARCHAR,
    year_quarter        VARCHAR
);

INSERT INTO skills_mart.dim_date_month
SELECT DISTINCT
    DATE_TRUNC('month', job_posted_date)::DATE  AS month_start_date,
    YEAR(job_posted_date)                       AS year,
    MONTH(job_posted_date)                      AS month,
    MONTHNAME(job_posted_date)                  AS month_name,
    QUARTER(job_posted_date)                    AS quarter,
    'Q' || QUARTER(job_posted_date)             AS quarter_name,
    YEAR(job_posted_date) || '-Q' || QUARTER(job_posted_date) AS year_quarter
FROM job_postings_fact
WHERE job_posted_date IS NOT NULL;

-- 3. Fact table
-- Grain: one row per skill_id + month_start_date + job_title_short
CREATE TABLE skills_mart.fact_skill_demand_monthly (
    skill_id                        INTEGER,
    month_start_date                DATE,
    job_title_short                 VARCHAR,
    postings_count                  INTEGER,
    remote_postings_count           INTEGER,
    health_insurance_postings_count INTEGER,
    no_degree_mention_count         INTEGER,
    salary_postings_count           INTEGER,  -- postings that list a yearly salary
    salary_year_sum                 DOUBLE,   -- sum so avg salary can be rebuilt at any level
    PRIMARY KEY (skill_id, month_start_date, job_title_short),
    FOREIGN KEY (skill_id) REFERENCES skills_mart.dim_skill(skill_id),
    FOREIGN KEY (month_start_date) REFERENCES skills_mart.dim_date_month(month_start_date)
);

INSERT INTO skills_mart.fact_skill_demand_monthly
WITH job_skills AS (
    SELECT
        sjd.skill_id,
        DATE_TRUNC('month', jpf.job_posted_date)::DATE AS month_start_date,
        jpf.job_title_short,
        jpf.job_work_from_home,
        jpf.job_health_insurance,
        jpf.job_no_degree_mention,
        jpf.salary_year_avg
    FROM job_postings_fact AS jpf
    INNER JOIN skills_job_dim AS sjd
        ON jpf.job_id = sjd.job_id
    WHERE jpf.job_posted_date IS NOT NULL
)
SELECT
    skill_id,
    month_start_date,
    job_title_short,
    COUNT(*)                                                AS postings_count,
    COUNT(*) FILTER (WHERE job_work_from_home)              AS remote_postings_count,
    COUNT(*) FILTER (WHERE job_health_insurance)            AS health_insurance_postings_count,
    COUNT(*) FILTER (WHERE job_no_degree_mention)           AS no_degree_mention_count,
    COUNT(salary_year_avg)                                  AS salary_postings_count,
    SUM(salary_year_avg)                                    AS salary_year_sum
FROM job_skills
GROUP BY
    skill_id,
    month_start_date,
    job_title_short;

-- Verify
SELECT 'Skill Dimension' AS table_name, COUNT(*) AS record_count FROM skills_mart.dim_skill
UNION ALL
SELECT 'Date Month Dimension', COUNT(*) FROM skills_mart.dim_date_month
UNION ALL
SELECT 'Skill Demand Fact', COUNT(*) FROM skills_mart.fact_skill_demand_monthly;

SELECT '=== Date Month Dimension Sample ===' AS info;
SELECT * FROM skills_mart.dim_date_month ORDER BY month_start_date DESC LIMIT 6;

-- Ratios are derived from the additive measures at query time, never stored
SELECT '=== Top Data Engineer Skills by Quarter (last 4 quarters) ===' AS info;
SELECT
    d.year_quarter,
    s.skills,
    SUM(f.postings_count) AS postings,
    ROUND(100.0 * SUM(f.remote_postings_count) / SUM(f.postings_count), 1) AS remote_pct,
    ROUND(SUM(f.salary_year_sum) / NULLIF(SUM(f.salary_postings_count), 0), 0) AS avg_salary
FROM skills_mart.fact_skill_demand_monthly AS f
JOIN skills_mart.dim_skill AS s ON f.skill_id = s.skill_id
JOIN skills_mart.dim_date_month AS d ON f.month_start_date = d.month_start_date
WHERE f.job_title_short = 'Data Engineer'
    AND d.year_quarter IN (
        SELECT DISTINCT year_quarter FROM skills_mart.dim_date_month
        ORDER BY year_quarter DESC LIMIT 4
    )
GROUP BY d.year_quarter, s.skills
QUALIFY ROW_NUMBER() OVER (PARTITION BY d.year_quarter ORDER BY SUM(f.postings_count) DESC) <= 3
ORDER BY d.year_quarter DESC, postings DESC;
