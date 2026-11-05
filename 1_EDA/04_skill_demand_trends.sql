/*
Question: How has demand for data engineering skills changed from 2023 to 2025?
- Look at ALL Data Engineer postings (not just remote) so each year has a big sample
- For each year, rank skills by number of postings and also show % of that year's postings
- Compare 2023 vs 2025 rank to find rising and falling skills
- Why? Queries 01-03 are a single snapshot. Knowing the direction a skill is moving
  helps decide what to learn next, not just what is popular right now
- Notes:
    - 2025 only has data through June. Using % of postings and rank (instead of raw counts)
      keeps the years comparable
    - Postings in 2025 list fewer skills on average (5.2 vs 6.1 in 2023), so almost every
      skill's % drops a bit. Rank is the more reliable signal for comparing years
*/

WITH de_postings AS (
    SELECT
        job_id,
        YEAR(job_posted_date) AS posted_year
    FROM job_postings_fact
    WHERE job_title_short = 'Data Engineer'
),

yearly_totals AS (
    SELECT
        posted_year,
        COUNT(*) AS total_postings
    FROM de_postings
    GROUP BY posted_year
),

skill_year AS (
    SELECT
        dp.posted_year,
        sd.skills,
        COUNT(*) AS skill_postings
    FROM de_postings AS dp
    INNER JOIN skills_job_dim AS sjd
        ON dp.job_id = sjd.job_id
    INNER JOIN skills_dim AS sd
        ON sjd.skill_id = sd.skill_id
    GROUP BY
        dp.posted_year,
        sd.skills
),

ranked AS (
    SELECT
        sy.posted_year,
        sy.skills,
        ROUND(100.0 * sy.skill_postings / yt.total_postings, 1) AS pct_of_postings,
        RANK() OVER (PARTITION BY sy.posted_year ORDER BY sy.skill_postings DESC) AS demand_rank
    FROM skill_year AS sy
    INNER JOIN yearly_totals AS yt
        ON sy.posted_year = yt.posted_year
)

-- pivot the years into columns with conditional aggregation
SELECT
    skills,
    MAX(demand_rank) FILTER (WHERE posted_year = 2023) AS rank_2023,
    MAX(demand_rank) FILTER (WHERE posted_year = 2024) AS rank_2024,
    MAX(demand_rank) FILTER (WHERE posted_year = 2025) AS rank_2025,
    MAX(pct_of_postings) FILTER (WHERE posted_year = 2023) AS pct_2023,
    MAX(pct_of_postings) FILTER (WHERE posted_year = 2025) AS pct_2025,
    -- positive = moved up the ranking
    MAX(demand_rank) FILTER (WHERE posted_year = 2023)
        - MAX(demand_rank) FILTER (WHERE posted_year = 2025) AS rank_change
FROM ranked
GROUP BY
    skills
HAVING
    MAX(demand_rank) FILTER (WHERE posted_year = 2025) <= 20
ORDER BY
    rank_2025;

/*
Insights:
- The top 5 barely moved: SQL and Python hold #1 and #2 every year, and Azure overtook
  AWS for #3 in 2025
- Biggest risers are the modern cloud data platforms: Databricks (#10 -> #6) and
  Snowflake (#11 -> #7). Their % of postings actually went UP while most skills went down
- PySpark (+6), Kubernetes (+4), Airflow (+3), GCP (+3) and Redshift (+3) are also climbing
- Biggest fallers are older big data tools: Hadoop (#8 -> #13) and Kafka (#7 -> #12).
  Hadoop dropped from 15.5% to 10.8% of postings
- Overall trend: the market is moving from self-managed Hadoop-era tooling to managed
  cloud platforms (Databricks, Snowflake) with Spark/PySpark + Airflow on top

┌────────────┬───────────┬───────────┬───────────┬──────────┬──────────┬─────────────┐
│   skills   │ rank_2023 │ rank_2024 │ rank_2025 │ pct_2023 │ pct_2025 │ rank_change │
│  varchar   │   int64   │   int64   │   int64   │  double  │  double  │    int64    │
├────────────┼───────────┼───────────┼───────────┼──────────┼──────────┼─────────────┤
│ sql        │         1 │         1 │         1 │     60.7 │     53.5 │           0 │
│ python     │         2 │         2 │         2 │     58.0 │     52.4 │           0 │
│ azure      │         4 │         4 │         3 │     32.6 │     31.2 │           1 │
│ aws        │         3 │         3 │         4 │     33.3 │     31.1 │          -1 │
│ spark      │         5 │         5 │         5 │     28.8 │     23.4 │           0 │
│ databricks │        10 │         7 │         6 │     14.8 │     17.5 │           4 │
│ snowflake  │        11 │         8 │         7 │     14.3 │     16.5 │           4 │
│ java       │         6 │         6 │         8 │     19.1 │     14.4 │          -2 │
│ airflow    │        12 │         9 │         9 │     13.7 │     12.2 │           3 │
│ gcp        │        13 │        13 │        10 │     11.9 │     12.1 │           3 │
│ scala      │         9 │        10 │        11 │     15.4 │     12.0 │          -2 │
│ kafka      │         7 │        12 │        12 │     15.6 │     11.9 │          -5 │
│ hadoop     │         8 │        11 │        13 │     15.5 │     10.8 │          -5 │
│ power bi   │        16 │        16 │        14 │     10.1 │     10.2 │           2 │
│ redshift   │        18 │        15 │        15 │      9.7 │      9.3 │           3 │
│ pyspark    │        22 │        17 │        16 │      8.6 │      8.9 │           6 │
│ nosql      │        14 │        14 │        17 │     11.8 │      8.4 │          -3 │
│ git        │        15 │        18 │        18 │     10.3 │      8.0 │          -3 │
│ tableau    │        17 │        20 │        19 │     10.1 │      7.9 │          -2 │
│ kubernetes │        24 │        24 │        20 │      8.0 │      7.1 │           4 │
├────────────┴───────────┴───────────┴───────────┴──────────┴──────────┴─────────────┤
│ 20 rows                                                                  7 columns │
└────────────────────────────────────────────────────────────────────────────────────┘
*/
