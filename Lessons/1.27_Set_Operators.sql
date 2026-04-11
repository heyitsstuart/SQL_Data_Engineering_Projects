-- UNION  and  UNION ALL
SELECT UNNEST([1, 1, 1, 2])
UNION
SELECT UNNEST([1, 1, 3]);



-- INTERSECT and INTERSECT ALL
SELECT UNNEST([1, 1, 1, 2])
INTERSECT
SELECT UNNEST([1, 1, 3]);

SELECT UNNEST([1, 1, 1, 2])
INTERSECT ALL
SELECT UNNEST([1, 1, 3]);

--EXCEPT and EXCEPT ALL
SELECT UNNEST([1, 1, 1, 2])
EXCEPT
SELECT UNNEST([1, 1, 3]);

SELECT UNNEST([1, 1, 1, 2])
EXCEPT ALL
SELECT UNNEST([1, 1, 3]);



--Example
USE data_jobs;

--2023 jobs data
CREATE TEMP TABLE jobs_2023 AS 
SELECT * EXCLUDE(job_id, job_posted_date)
FROM job_postings_fact
WHERE EXTRACT(YEAR FROM job_posted_date) = 2023;

--2024 jobs table
CREATE TEMP TABLE jobs_2024 AS 
SELECT * EXCLUDE(job_id, job_posted_date)
FROM job_postings_fact
WHERE EXTRACT(YEAR FROM job_posted_date) = 2024;

--which unique job postings apppeared appeared in either 2023 or 2024
SELECT 
    'jobs_2023' AS table_name,
    COUNT(*) 
FROM jobs_2023
UNION
SELECT 
    'jobs_2024'AS table_name,
    COUNT(*)  
FROM jobs_2024;


-- which job postings appeared across both years, counting duplicates?
SELECT * FROM jobs_2023
UNION ALL
SELECT * FROM jobs_2024;

--which job postings appeared in 2023 but not in 2024
SELECT * FROM jobs_2023
EXCEPT
SELECT * FROM jobs_2024;


--which job postings from 2023 remain after subtracting matching 2024 postings, one-for-one?
SELECT * FROM jobs_2023
EXCEPT ALL
SELECT * FROM jobs_2024;

--which job_postings appeared in both 2023 and 2024
SELECT * FROM jobs_2023
INTERSECT
SELECT * FROM jobs_2024;

--which job_postings appeared in both years, preserving duplicate counts?
SELECT * FROM jobs_2023
INTERSECT ALL
SELECT * FROM jobs_2024;