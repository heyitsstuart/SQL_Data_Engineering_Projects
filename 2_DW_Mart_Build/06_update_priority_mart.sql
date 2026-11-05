-- Step 6: Mart - Incremental update of the priority mart (MERGE / upsert)
-- Run after Step 5
-- Scenario: priorities changed. Data Engineer moves up to level 1 and Data Scientist
-- gets added at level 2. Instead of rebuilding the snapshot, apply only the changes.
-- Both MERGEs are written so this script can be run more than once safely

-- 1. Desired state of the roles table
CREATE OR REPLACE TEMP TABLE src_priority_roles AS
SELECT * FROM (
    VALUES
        (1, 'Data Engineer',        1),
        (2, 'Senior Data Engineer', 1),
        (3, 'Software Engineer',    3),
        (4, 'Data Scientist',       2)
) AS t(role_id, role_name, priority_lvl);

-- 2. Upsert roles (UPDATE changed levels, INSERT new roles)
MERGE INTO priority_mart.priority_roles AS tgt
USING src_priority_roles AS src
    ON tgt.role_id = src.role_id
WHEN MATCHED AND tgt.priority_lvl IS DISTINCT FROM src.priority_lvl THEN
    UPDATE SET priority_lvl = src.priority_lvl
WHEN NOT MATCHED THEN
    INSERT (role_id, role_name, priority_lvl)
    VALUES (src.role_id, src.role_name, src.priority_lvl);

-- 3. Rebuild what the snapshot *should* look like from the warehouse
CREATE OR REPLACE TEMP TABLE src_priority_jobs AS
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

-- Capture counts before the merge so the change is visible in the output
CREATE OR REPLACE TEMP TABLE snapshot_before AS
SELECT job_title_short, priority_lvl, COUNT(*) AS job_count
FROM priority_mart.priority_jobs_snapshot
GROUP BY ALL;

-- 4. Sync the snapshot
--   WHEN MATCHED (priority changed)  -> UPDATE, only touches rows that actually changed
--   WHEN NOT MATCHED                 -> INSERT new jobs (all the Data Scientist rows)
--   WHEN NOT MATCHED BY SOURCE       -> DELETE jobs that dropped out of the source
MERGE INTO priority_mart.priority_jobs_snapshot AS tgt
USING src_priority_jobs AS src
    ON tgt.job_id = src.job_id
WHEN MATCHED AND tgt.priority_lvl IS DISTINCT FROM src.priority_lvl THEN
    UPDATE SET
        priority_lvl = src.priority_lvl,
        updated_at   = src.updated_at
WHEN NOT MATCHED THEN
    INSERT (job_id, job_title_short, company_name, job_posted_date, salary_year_avg, priority_lvl, updated_at)
    VALUES (src.job_id, src.job_title_short, src.company_name, src.job_posted_date, src.salary_year_avg, src.priority_lvl, src.updated_at)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

-- Verify
SELECT '=== Priority Roles (after update) ===' AS info;
SELECT * FROM priority_mart.priority_roles ORDER BY priority_lvl, role_id;

SELECT '=== Snapshot Before vs After ===' AS info;
WITH snapshot_after AS (
    SELECT job_title_short, priority_lvl, COUNT(*) AS job_count, MAX(updated_at) AS last_updated
    FROM priority_mart.priority_jobs_snapshot
    GROUP BY ALL
)
SELECT
    COALESCE(a.job_title_short, b.job_title_short) AS job_title_short,
    b.priority_lvl AS priority_before,
    a.priority_lvl AS priority_after,
    b.job_count AS jobs_before,
    a.job_count AS jobs_after,
    a.last_updated
FROM snapshot_after AS a
FULL OUTER JOIN snapshot_before AS b
    ON a.job_title_short = b.job_title_short
ORDER BY priority_after, jobs_after DESC;
