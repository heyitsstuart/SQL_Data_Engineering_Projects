-- Run the script with: .read Lessons/1.24/priority_jobs_snapshot.sql

--source table is the temp table created below and the target table is the initially created prority_jobs_snapshot

-- Create a temp table to reference in the statements below
CREATE OR REPLACE TEMP TABLE src_priority_jobs AS
SELECT 
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    r.priority_lvl,
    CURRENT_TIMESTAMP AS updated_at
FROM
    data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id
INNER JOIN staging.priority_roles AS r
ON jpf.job_title_short = r.role_name;

-- Update statement to capture the matched rows that might have changed between the source and target table
UPDATE main.priority_jobs_snapshot AS tgt 
SET 
    priority_lvl = src.priority_lvl,
    updated_at = src.updated_at
FROM src_priority_jobs AS src
WHERE tgt.job_id = src.job_id
    AND tgt.priority_lvl IS DISTINCT FROM src.priority_lvl; --Checks row by row if it changed


--Insert statement to insert any new entries made to the priority_roles table into the target table
INSERT INTO main.priority_jobs_snapshot (
    job_id,
    job_title_short,
    company_name,
    job_posted_date,
    salary_year_avg,
    priority_lvl,
    updated_at
)
SELECT
    src.job_id,
    src.job_title_short,
    src.company_name,
    src.job_posted_date,
    src.salary_year_avg,
    src.priority_lvl,
    src.updated_at
FROM src_priority_jobs AS src;





SELECT
    job_title_short,
    COUNT(*) AS job_count,
    MIN(priority_lvl) AS priority_lvl,
    MIN(updated_at) AS updated_at
FROM priority_jobs_snapshot
GROUP BY job_title_short
ORDER BY job_count DESC;