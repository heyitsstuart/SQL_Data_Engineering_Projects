/*
Question: What are the most in-demand skills for remote data engineers?
- Count how many remote Data Engineer postings mention each skill
- Return the top 10
- Why? Shows which skills open the most doors for someone targeting remote data engineering work
*/

SELECT
    sd.skills,
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
ORDER BY
    demand_count DESC
LIMIT 10;

/*
Insights (out of 43,853 remote Data Engineer postings):
- SQL (29,221) and Python (28,776) are almost tied and each show up in ~2 out of 3 postings.
  They are the baseline, not a differentiator
- Cloud is next: AWS (17,823) leads Azure (14,143), with GCP (6,446) a distant third
- Spark (12,799) is the top processing engine, and Airflow (9,996) is the go-to orchestrator
- Snowflake and Databricks (~8K each) are close, so knowing at least one modern cloud
  warehouse/lakehouse platform matters
- Java is the only "traditional" language besides Python in the top 10

┌────────────┬──────────────┐
│   skills   │ demand_count │
│  varchar   │    int64     │
├────────────┼──────────────┤
│ sql        │        29221 │
│ python     │        28776 │
│ aws        │        17823 │
│ azure      │        14143 │
│ spark      │        12799 │
│ airflow    │         9996 │
│ snowflake  │         8639 │
│ databricks │         8183 │
│ java       │         7267 │
│ gcp        │         6446 │
├────────────┴──────────────┤
│ 10 rows         2 columns │
└───────────────────────────┘
*/
