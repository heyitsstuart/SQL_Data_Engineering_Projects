-- Count rows with standard aggregation
SELECT
    COUNT(*)
FROM
    job_postings_fact;

-- Count rows with window functions
SELECT
    job_id,
    COUNT(*) OVER()
FROM
    job_postings_fact;

-- using PARTITION BY to get the average hourly salary for each job title
SELECT
    job_id,
    job_title_short,
    company_id,
    salary_hour_avg,
    AVG(salary_hour_avg) OVER(
        PARTITION BY job_title_short, company_id
    )
FROM
    job_postings_fact
WHERE
    salary_hour_avg IS NOT NULL
ORDER BY
    RANDOM()
LIMIT 20;

-- using ORDER BY with the RANK() window function to rank each job posting ordered by salary_hour_avg - without partitioning
SELECT
    job_id,
    job_title_short,
    salary_hour_avg,
    RANK() OVER(
        ORDER BY salary_hour_avg DESC  --DESC changes the default ranking order by making the highest salary ranked first
    ) AS rank_hourly_salary
FROM
    job_postings_fact
WHERE
    salary_hour_avg IS NOT NULL
ORDER BY
    salary_hour_avg DESC
LIMIT 20;


-- using both PARTITION BY (to group rows)  and ORDER BY (to define the sequence in those partitions) tp get the running average
SELECT
    job_posted_date,
    job_title_short,
    salary_hour_avg,
    AVG(salary_hour_avg) OVER(
        PARTITION BY job_title_short
        ORDER BY job_posted_date
    ) AS running_avg_hourly_by_title
FROM
    job_postings_fact
WHERE
    salary_hour_avg IS NOT NULL
ORDER BY
    job_title_short,
    job_posted_date
LIMIT 20;

--PARTION BY & ORDER BY to rank by job title
SELECT
    job_id,
    job_title_short,
    salary_hour_avg,
    RANK() OVER(
        PARTITION BY job_title_short
        ORDER BY salary_hour_avg DESC  --DESC changes the default ranking order by making the highest salary ranked first
    ) AS rank_hourly_salary
FROM
    job_postings_fact
WHERE
    salary_hour_avg IS NOT NULL
ORDER BY 
    salary_hour_avg DESC,
    job_title_short
LIMIT 20;


-- Ranking functions - DENSE_RANK - isn't like the normal statistical ranking - it doesn't skip ranks - e.g.  1, 2, 2, 2, 3 (instead of 5)
SELECT
    job_id,
    job_title_short,
    salary_hour_avg,
    DENSE_RANK() OVER(
        ORDER BY salary_hour_avg DESC  --DESC changes the default ranking order by making the highest salary ranked first
    ) AS rank_hourly_salary
FROM
    job_postings_fact
WHERE
    salary_hour_avg IS NOT NULL
ORDER BY
    salary_hour_avg DESC
LIMIT 50;

-- ROW_NUMBER() - Providing a new job_id
SELECT 
    *,
    ROW_NUMBER() OVER(
        ORDER BY job_posted_date
    )
FROM
    job_postings_fact
ORDER BY
    job_posted_date
LIMIT 20;

-- LAG() function is a navigation function that lets you see the previous value for each new related rowv- e.g. you can see the previous salary for a company everytime they posted a new job
SELECT
    job_id,
    company_id,
    job_title,
    job_title_short,
    job_posted_date,
    salary_year_avg,
    LAG(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY job_posted_date
    ) AS previous_posting_salary,
    salary_year_avg -   LAG(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY job_posted_date
    ) AS salary_change
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
ORDER BY
    company_id,
    job_posted_date
LIMIT 60;