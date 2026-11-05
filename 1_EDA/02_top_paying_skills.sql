/*
Question: What are the highest-paying skills for data engineers?
- Calculate the median salary for each skill required in remote data engineer positions
- Include skill frequency to identify both salary and demand
- Only 1,576 of the 43,853 remote DE postings (~3.6%) list a yearly salary, so the median
  for a skill is often based on very few postings. To avoid ranking on noise, only keep
  skills with at least 30 salaried postings and show that sample size next to the median
  (e.g. without this, Rust tops the list at $210K but that is based on just 23 salaries)
- Why? Helps identify which skills command the highest compensation while also showing
  how common those skills are, providing a more complete picture for skill development priorities
*/

SELECT
    sd.skills,
    ROUND(MEDIAN(jpf.salary_year_avg), 0) AS median_salary,
    COUNT(jpf.salary_year_avg) AS salary_sample_size,   -- COUNT(col) skips NULLs
    COUNT(jpf.*) AS demand_count
FROM job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id
WHERE
    jpf.job_title_short = 'Data Engineer'
    AND jpf.job_work_from_home = True
GROUP BY
    sd.skills
HAVING
    COUNT(jpf.salary_year_avg) >= 30
ORDER BY
    median_salary DESC,
    demand_count DESC
LIMIT 25;

/*
Insights:
- Terraform ($184K) is the standout: high median salary AND a solid sample (193 salaries,
  3,248 postings). Infrastructure-as-code skills pay a premium
- Golang ($184K) and Spring ($175.5K) also pay well but are niche (under 40 salaried postings each)
- Kubernetes ($150.5K) and Airflow ($150K) combine strong pay with high demand
  (4,202 and 9,996 postings), which makes them the most "bankable" high-pay skills
- The core big data stack (Spark, PySpark, Kafka, Scala) clusters around $137K - $145K
- SQL and Python don't make the top 25 for salary. Everyone asks for them, so they don't
  push pay up on their own (see 03_optimal_skills.sql)

┌────────────┬───────────────┬────────────────────┬──────────────┐
│   skills   │ median_salary │ salary_sample_size │ demand_count │
│  varchar   │    double     │       int64        │    int64     │
├────────────┼───────────────┼────────────────────┼──────────────┤
│ terraform  │      184000.0 │                193 │         3248 │
│ golang     │      184000.0 │                 39 │          912 │
│ spring     │      175500.0 │                 33 │          364 │
│ typescript │      151000.0 │                 39 │          388 │
│ kubernetes │      150500.0 │                147 │         4202 │
│ airflow    │      150000.0 │                386 │         9996 │
│ ruby       │      150000.0 │                 48 │          736 │
│ kafka      │      145000.0 │                292 │         6415 │
│ spark      │      140000.0 │                503 │        12799 │
│ pyspark    │      140000.0 │                152 │         4898 │
│ git        │      140000.0 │                208 │         4641 │
│ pandas     │      140000.0 │                 98 │         2929 │
│ go         │      140000.0 │                113 │         1997 │
│ word       │      140000.0 │                 92 │          650 │
│ aws        │      137320.0 │                783 │        17823 │
│ scala      │      137290.0 │                247 │         6304 │
│ gcp        │      136000.0 │                196 │         6446 │
│ looker     │      136000.0 │                 87 │         1574 │
│ dynamodb   │      136000.0 │                 55 │         1082 │
│ mongodb    │      135750.0 │                136 │         3512 │
│ snowflake  │      135500.0 │                438 │         8639 │
│ python     │      135000.0 │               1133 │        28776 │
│ java       │      135000.0 │                303 │         7267 │
│ hadoop     │      135000.0 │                198 │         5447 │
│ docker     │      135000.0 │                144 │         4316 │
├────────────┴───────────────┴────────────────────┴──────────────┤
│ 25 rows                                              4 columns │
└────────────────────────────────────────────────────────────────┘
*/
