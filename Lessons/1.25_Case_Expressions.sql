-- Bucket salaries
SELECT
    job_title_short,
    salary_hour_avg,
    CASE
        WHEN salary_hour_avg < 25 THEN 'Low'
        WHEN salary_hour_avg < 50 THEN 'Medium'
        ELSE 'High'
    END AS salary_category
FROM data_jobs.job_postings_fact
WHERE salary_hour_avg IS NOT NULL
LIMIT 10;


-- Handling missing data (NULLs)
SELECT
    job_title_short,
    salary_hour_avg,
    CASE
        WHEN salary_hour_avg IS NULL THEN 'Missing'
        WHEN salary_hour_avg < 25 THEN 'Low'
        WHEN salary_hour_avg < 50 THEN 'Medium'
        ELSE 'High'
    END AS salary_category
FROM data_jobs.job_postings_fact
LIMIT 10;

--Categorizing Categorical Values
SELECT
    job_title,
    CASE
        WHEN job_title LIKE '%Data%' AND job_title LIKE '%Analyst%' THEN 'Data Analyst'
        WHEN job_title LIKE '%Data%' AND job_title LIKE '%Engineer%' THEN 'Data Engineer'
        WHEN job_title LIKE '%Data%' AND job_title LIKE '%Scientist%' THEN 'Data Scientist'
        ELSE 'Other'
    END AS job_title_category,
    job_title_short
FROM data_jobs.job_postings_fact
ORDER BY RANDOM()
LIMIT 20;


--Conditional Aggregation - Calculate median salaries for different buckets
SELECT
    job_title_short,
    COUNT(*) AS total_postings,
    MEDIAN(  
        CASE
            WHEN salary_year_avg < 100_000 THEN salary_year_avg
        END
        ) AS median_low_salary,
    MEDIAN(  
        CASE
            WHEN salary_year_avg >= 100_000 THEN salary_year_avg
        END
        ) AS median_high_salary
FROM data_jobs.job_postings_fact
WHERE salary_year_avg IS NOT NULL
GROUP BY job_title_short;



--Compute a standardized_salary using yearly salary and adjusted hourly salary (e.g 2080 hours/year)
WITH salaries AS ( 
    SELECT
        job_title_short,
        salary_hour_avg,
        salary_year_avg,
        CASE
            WHEN salary_year_avg IS NOT NULL THEN salary_year_avg
            WHEN salary_hour_avg IS NOT NULL THEN salary_hour_avg*2080
        END AS standardized_salary
    FROM data_jobs.job_postings_fact
)
SELECT
    *,
    CASE
        WHEN standardized_salary IS NULL THEN 'Missing'
        WHEN standardized_salary < 75_000 THEN 'Low'
        WHEN standardized_salary < 150_000 THEN 'Medium'
        ELSE 'High'
    END AS salary_bucket
FROM salaries
ORDER BY standardized_salary DESC
LIMIT 10;