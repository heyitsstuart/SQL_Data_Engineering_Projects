
--EXTRACT
SELECT 
    job_posted_date,
    EXTRACT(YEAR FROM job_posted_date) AS job_posted_year,
    EXTRACT(MONTH FROM job_posted_date) AS job_posted_month,
    EXTRACT(DAY FROM job_posted_date) AS job_posted_day
FROM data_jobs.job_postings_fact
LIMIT 10;


SELECT
    EXTRACT(YEAR FROM job_posted_date) AS job_posted_year,
    EXTRACT(MONTH FROM job_posted_date) AS job_posted_month,
    COUNT(job_id) AS job_count
FROM data_jobs.job_postings_fact
WHERE job_title_short = 'Data Engineer'
GROUP BY 
    EXTRACT(YEAR FROM job_posted_date),
    EXTRACT(MONTH FROM job_posted_date)
ORDER BY 
    job_posted_year,
    job_posted_month;


--DATE_TRUNC
SELECT
    job_posted_date,
    DATE_TRUNC('year', job_posted_date) AS job_posted_year,
    DATE_TRUNC('quarter', job_posted_date) AS job_posted_quarter,
    DATE_TRUNC('month', job_posted_date) AS job_posted_month,
    DATE_TRUNC('week', job_posted_date) AS job_posted_week,
    DATE_TRUNC('day', job_posted_date) AS job_posted_day,
    DATE_TRUNC('hour', job_posted_date) AS job_posted_hour
FROM data_jobs.job_postings_fact
ORDER BY RANDOM()
LIMIT 10;

SELECT
    DATE_TRUNC('month', job_posted_date) AS job_posted_month,
    COUNT(job_id) AS job_count
FROM data_jobs.job_postings_fact
WHERE 
    job_title_short = 'Data Engineer' AND
    EXTRACT(YEAR FROM job_posted_date) = 2024
GROUP BY 
    DATE_TRUNC('month', job_posted_date)
ORDER BY 
    job_posted_month;


---AT TIME ZONE
--The first time you use AT TIME ZONE is used assumes the machine's time zone. 
--So if you want to change to another time zone, you need to use it the second time
--You first use it to specify the time zone of the data itself and the second time you specify the time zone you need it in
SELECT
    job_title_short,
    job_location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EAT'
FROM
    data_jobs.job_postings_fact
WHERE 
    job_location LIKE 'New York, NY';


SELECT
    EXTRACT(HOUR FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EAT') AS job_posted_hour,
    COUNT(job_id)
FROM
    data_jobs.job_postings_fact
WHERE 
    job_location LIKE 'New York, NY'
GROUP BY
    EXTRACT(HOUR FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EAT')
ORDER BY
    job_posted_hour;