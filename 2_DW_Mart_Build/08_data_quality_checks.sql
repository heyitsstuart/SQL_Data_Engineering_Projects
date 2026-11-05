-- Step 8: Data quality checks across the warehouse and marts
-- Run after Step 7
-- Each check returns the number of offending rows. 0 = PASS.
-- Warnings are things worth knowing about in the source data but not pipeline bugs

CREATE OR REPLACE TEMP TABLE dq_results AS

-- ---------- Warehouse: keys & referential integrity ----------
SELECT 'warehouse' AS layer, 'job_postings_fact: duplicate job_id' AS check_name, 'error' AS severity,
    (SELECT COUNT(*) - COUNT(DISTINCT job_id) FROM job_postings_fact) AS failed_rows
UNION ALL
SELECT 'warehouse', 'job_postings_fact: company_id not in company_dim', 'error',
    (SELECT COUNT(*) FROM job_postings_fact AS f
     WHERE f.company_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM company_dim AS c WHERE c.company_id = f.company_id))
UNION ALL
SELECT 'warehouse', 'skills_job_dim: job_id not in fact', 'error',
    (SELECT COUNT(*) FROM skills_job_dim AS b
     WHERE NOT EXISTS (SELECT 1 FROM job_postings_fact AS f WHERE f.job_id = b.job_id))
UNION ALL
SELECT 'warehouse', 'skills_job_dim: skill_id not in skills_dim', 'error',
    (SELECT COUNT(*) FROM skills_job_dim AS b
     WHERE NOT EXISTS (SELECT 1 FROM skills_dim AS s WHERE s.skill_id = b.skill_id))

-- ---------- Warehouse: value checks ----------
UNION ALL
SELECT 'warehouse', 'job_postings_fact: null job_posted_date', 'error',
    (SELECT COUNT(*) FROM job_postings_fact WHERE job_posted_date IS NULL)
UNION ALL
SELECT 'warehouse', 'job_postings_fact: posted date in the future', 'error',
    (SELECT COUNT(*) FROM job_postings_fact WHERE job_posted_date > CURRENT_TIMESTAMP)
UNION ALL
SELECT 'warehouse', 'job_postings_fact: salary_year_avg outside $10K-$1M', 'warning',
    (SELECT COUNT(*) FROM job_postings_fact
     WHERE salary_year_avg NOT BETWEEN 10000 AND 1000000)
UNION ALL
SELECT 'warehouse', 'job_postings_fact: null job_country', 'warning',
    (SELECT COUNT(*) FROM job_postings_fact WHERE job_country IS NULL)
UNION ALL
SELECT 'warehouse', 'job_postings_fact: postings with no skills', 'warning',
    (SELECT COUNT(*) FROM job_postings_fact AS f
     WHERE NOT EXISTS (SELECT 1 FROM skills_job_dim AS b WHERE b.job_id = f.job_id))

-- ---------- Marts: reconcile back to the warehouse ----------
UNION ALL
SELECT 'flat_mart', 'row count differs from job_postings_fact', 'error',
    (SELECT ABS((SELECT COUNT(*) FROM flat_mart.job_postings) - (SELECT COUNT(*) FROM job_postings_fact)))
UNION ALL
SELECT 'flat_mart', 'skill_count differs from bridge table total', 'error',
    (SELECT ABS((SELECT SUM(skill_count) FROM flat_mart.job_postings) - (SELECT COUNT(*) FROM skills_job_dim)))
UNION ALL
SELECT 'skills_mart', 'sum(postings_count) differs from bridge table total', 'error',
    (SELECT ABS((SELECT SUM(postings_count) FROM skills_mart.fact_skill_demand_monthly)
              - (SELECT COUNT(*) FROM skills_job_dim AS b
                 JOIN job_postings_fact AS f ON f.job_id = b.job_id
                 WHERE f.job_posted_date IS NOT NULL)))
UNION ALL
SELECT 'skills_mart', 'remote count greater than postings count', 'error',
    (SELECT COUNT(*) FROM skills_mart.fact_skill_demand_monthly WHERE remote_postings_count > postings_count)
UNION ALL
SELECT 'priority_mart', 'snapshot rows not matching a priority role', 'error',
    (SELECT COUNT(*) FROM priority_mart.priority_jobs_snapshot AS s
     WHERE NOT EXISTS (SELECT 1 FROM priority_mart.priority_roles AS r WHERE r.role_name = s.job_title_short))
UNION ALL
SELECT 'priority_mart', 'snapshot priority_lvl out of sync with roles', 'error',
    (SELECT COUNT(*) FROM priority_mart.priority_jobs_snapshot AS s
     JOIN priority_mart.priority_roles AS r ON r.role_name = s.job_title_short
     WHERE s.priority_lvl IS DISTINCT FROM r.priority_lvl)
UNION ALL
SELECT 'priority_mart', 'snapshot row count differs from source', 'error',
    (SELECT ABS((SELECT COUNT(*) FROM priority_mart.priority_jobs_snapshot)
              - (SELECT COUNT(*) FROM job_postings_fact AS f
                 JOIN priority_mart.priority_roles AS r ON f.job_title_short = r.role_name)))
UNION ALL
SELECT 'company_mart', 'sum(postings_count) differs from eligible fact rows', 'error',
    (SELECT ABS((SELECT SUM(postings_count) FROM company_mart.fact_company_hiring_monthly)
              - (SELECT COUNT(*) FROM job_postings_fact
                 WHERE company_id IS NOT NULL AND job_posted_date IS NOT NULL AND job_country IS NOT NULL)))
UNION ALL
SELECT 'company_mart', 'job_title_id mapped to more than one role', 'warning',
    (SELECT COUNT(*) FROM (
        SELECT job_title_id FROM company_mart.bridge_job_title
        GROUP BY job_title_id HAVING COUNT(*) > 1));

SELECT '=== Data Quality Results ===' AS info;
SELECT
    layer,
    check_name,
    severity,
    failed_rows,
    CASE
        WHEN failed_rows = 0 THEN 'PASS'
        WHEN severity = 'warning' THEN 'WARN'
        ELSE 'FAIL'
    END AS status
FROM dq_results
ORDER BY
    CASE WHEN failed_rows = 0 THEN 2 WHEN severity = 'warning' THEN 1 ELSE 0 END,
    layer;

SELECT
    COUNT(*) FILTER (WHERE failed_rows = 0) AS passed,
    COUNT(*) FILTER (WHERE failed_rows > 0 AND severity = 'warning') AS warnings,
    COUNT(*) FILTER (WHERE failed_rows > 0 AND severity = 'error') AS failed
FROM dq_results;
