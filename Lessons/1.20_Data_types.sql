SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'job_postings_fact';

DESCRIBE job_postings_fact;

DESCRIBE
SELECT
    job_title_short,
    salary_year_avg
FROM 
    job_postings_fact;
/*
Casting:
Used to convert data within queries to a different data type.
*/
SELECT CAST(123 AS VARCHAR);
SELECT CAST('123' AS INTEGER);

SELECT --job_id and company_id were changed to VARCHAR so that they can be appended/ concatenated
    CAST(job_id AS VARCHAR) || '-' || CAST(company_id AS VARCHAR),
    CAST(job_work_from_home AS INT) AS job_work_from_home,
    CAST(job_posted_date AS DATE) AS job_posted_date,
    CAST(salary_year_avg AS DECIMAL(10,0)) AS salary_year_avg
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
LIMIT 10;

/*
esides CAST, DuckDB supports the use of another option used in other databases (::)
*/
SELECT --job_id and company_id were changed to VARCHAR so that they can be appended/ concatenated
    job_id :: VARCHAR || '-' || company_id :: VARCHAR,
    job_work_from_home :: INT AS job_work_from_home,
    job_posted_date :: DATE AS job_posted_date,
    salary_year_avg :: DECIMAL(10,0) AS salary_year_avg
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
LIMIT 10;

SELECT (3 + 5.5)::INT;

