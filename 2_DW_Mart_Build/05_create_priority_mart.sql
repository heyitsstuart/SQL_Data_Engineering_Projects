-- Step 5: Mart - Create priority roles mart (snapshot mart)
-- Run after Step 4
-- A small lookup of roles I'm targeting plus a snapshot of every matching job,
-- tagged with that role's priority level. Step 6 then keeps it in sync with MERGE

DROP SCHEMA IF EXISTS priority_mart CASCADE;

CREATE SCHEMA priority_mart;

-- 1. Priority roles (1 = highest priority)
CREATE TABLE priority_mart.priority_roles (
    role_id         INTEGER     PRIMARY KEY,
    role_name       VARCHAR     UNIQUE,
    priority_lvl    INTEGER
);

INSERT INTO priority_mart.priority_roles (role_id, role_name, priority_lvl)
VALUES
    (1, 'Data Engineer',        2),
    (2, 'Senior Data Engineer', 1),
    (3, 'Software Engineer',    3);

-- 2. Jobs snapshot
CREATE TABLE priority_mart.priority_jobs_snapshot (
    job_id              INTEGER     PRIMARY KEY,
    job_title_short     VARCHAR,
    company_name        VARCHAR,
    job_posted_date     TIMESTAMP,
    salary_year_avg     DOUBLE,
    priority_lvl        INTEGER,
    updated_at          TIMESTAMP
);

INSERT INTO priority_mart.priority_jobs_snapshot
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    r.priority_lvl,
    CURRENT_TIMESTAMP AS updated_at
FROM job_postings_fact AS jpf
LEFT JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id
INNER JOIN priority_mart.priority_roles AS r
    ON jpf.job_title_short = r.role_name;

-- Verify
SELECT 'Priority Roles' AS table_name, COUNT(*) AS record_count FROM priority_mart.priority_roles
UNION ALL
SELECT 'Priority Jobs Snapshot', COUNT(*) FROM priority_mart.priority_jobs_snapshot;

SELECT '=== Priority Roles ===' AS info;
SELECT * FROM priority_mart.priority_roles ORDER BY priority_lvl;

SELECT '=== Snapshot by Role ===' AS info;
SELECT
    job_title_short,
    priority_lvl,
    COUNT(*) AS job_count,
    MIN(updated_at) AS updated_at
FROM priority_mart.priority_jobs_snapshot
GROUP BY job_title_short, priority_lvl
ORDER BY priority_lvl, job_count DESC;
