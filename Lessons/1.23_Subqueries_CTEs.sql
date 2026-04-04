-- subqueries
SELECT *
FROM (
    SELECT *
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
        OR salary_hour_avg IS NOT NULL
)
LIMIT 10;

--Show  each job's salary next to the overall market median
SELECT 
    job_title_short,
    salary_year_avg,
    (
    SELECT MEDIAN(salary_year_avg)
    FROM job_postings_fact
) AS market_median_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
LIMIT 10;

--Stage only jobs that are remote before aggregating to determine the remote median salary per job
SELECT 
    job_title_short,
    MEDIAN(salary_year_avg) AS median_salary,
    (
    SELECT MEDIAN(salary_year_avg)
    FROM job_postings_fact
    -- set it's own filter because the filter of the other subquery doesn't affect it
    WHERE job_work_from_home = TRUE
) AS market_remote_median_salary
FROM (
    SELECT
        job_title_short,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_work_from_home = TRUE
)
WHERE salary_year_avg IS NOT NULL
GROUP BY job_title_short
LIMIT 10;


-- Keep only the job titles whose median salary is above the overall median
SELECT 
    job_title_short,
    MEDIAN(salary_year_avg) AS median_salary,
    (
    SELECT MEDIAN(salary_year_avg)
    FROM job_postings_fact
    -- set it's own filter because the filter of the other subquery doesn't affect it
    WHERE job_work_from_home = TRUE
) AS market_remote_median_salary
FROM (
    SELECT
        job_title_short,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_work_from_home = TRUE
)
WHERE salary_year_avg IS NOT NULL
GROUP BY job_title_short
HAVING MEDIAN(salary_year_avg) > (
    SELECT MEDIAN(salary_year_avg)
    FROM job_postings_fact
    -- set it's own filter because the filter of the other subquery doesn't affect it
    WHERE job_work_from_home = TRUE
)
LIMIT 10;



-- CTE
WITH valid_salaries AS (
    SELECT *
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
    OR salary_hour_avg IS NOT NULL
)
SELECT *
FROM valid_salaries
LIMIT 10;

