SELECT LENGTH('SQL');
SELECT CHAR_LENGTH('SQL');


SELECT LOWER('SQL');
SELECT UPPER('sql');

--Substring extraction
SELECT LEFT('SQL', 2);
SELECT RIGHT('SQL', 2);
SELECT SUBSTRING('SQL', 2, 2);


--Concatination
SELECT CONCAT('SQL', '-', 'Functions');
--Same as
SELECT 'SQL' || '-' || 'Functions';

--Trimming: TRIM() removes whitespace from both ends, LTRIM() from the left, and RTRIM from the right
SELECT TRIM(' SQL ');

--Replacement
SELECT REPLACE('SQL', 'Q', '_');

SELECT REGEXP_REPLACE('data.nerd@gmail.com', '^.*(@)', '\1'); --Used AI's assistance, it replaces with @gmail.com


-- Final example on text functions
WITH title_lower AS (
    SELECT
        job_title,
        LOWER(TRIM(job_title)) AS job_title_clean
    FROM job_postings_fact
)
SELECT
    job_title,
    CASE
        WHEN job_title_clean LIKE '%data%' AND job_title_clean LIKE '%analyst%' THEN 'Data Analyst'
        WHEN job_title_clean LIKE '%data%' AND job_title_clean LIKE '%engineer%' THEN 'Data Engineer'
        WHEN job_title_clean LIKE '%data%' AND job_title_clean LIKE '%scientist%' THEN 'Data Scientist'
        ELSE 'Other'
    END AS job_title_category
FROM title_lower
ORDER BY RANDOM()
LIMIT 20;



--NULL Functions

--NULLIF()
SELECT NULLIF(10, 10);   --> Returns NULL
SELECT NULLIF(8, 25);   -->Returns 8
SELECT NULLIF(40, 20);    ---Returns 40


SELECT
    MEDIAN(NULLIF(salary_year_avg, 0)), --NULLIF makes the value NULL if it is zero
    MEDIAN(NULLIF(salary_hour_avg, 0)) 
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL OR salary_year_avg IS NOT NULL
LIMIT 20;

--COALESCE - Returns the first non-NULL value
SELECT COALESCE(NULL, 1, 2);
SELECT COALESCE(NULL, NULL, 2);

SELECT
    salary_year_avg, --NULLIF makes the value NULL if it is zero
    salary_hour_avg,
    COALESCE(salary_year_avg, salary_hour_avg*2080)
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL OR salary_year_avg IS NOT NULL
LIMIT 20;

--Example
SELECT
    job_title_short,
    salary_year_avg,
    salary_hour_avg,
    COALESCE(salary_year_avg, salary_hour_avg*2080) AS standardized_salary,
    CASE
        WHEN COALESCE(salary_year_avg, salary_hour_avg*2080) IS NULL THEN 'Missing'
        WHEN COALESCE(salary_year_avg, salary_hour_avg*2080) < 75_000 THEN 'Low'
        WHEN COALESCE(salary_year_avg, salary_hour_avg*2080) < 150_000 THEN 'Medium'
        ELSE 'High'
    END AS salary_bucket
FROM job_postings_fact
ORDER BY standardized_salary DESC;