# Exploratory Data Analysis w/ SQL: Data Engineer Job Market

![Project One Overview](../Images/1_1_Project1_EDA.png)

A SQL project analysing the data engineer job market using ~1.6M real world job postings (Jan 2023 - Jun 2025). It demonstrates my ability to **write production-quality analytical SQL, design efficient queries, and turn business questions into data-driven insights**.

## Executive Summary
- ✅ **Project scope:** Built 4 analytical queries that answer key questions about the data engineer job market
- ✅ **Data modeling:** Used multi-table joins across fact, dimension and bridge tables to extract insights
- ✅ **Analytics:** Applied aggregations, window functions, log scoring and conditional aggregation to rank skills by demand, salary, overall value and trend
- ✅ **Data quality:** Checked sample sizes behind every salary figure so rankings aren't driven by a handful of postings
- ✅ **Outcomes:** Delivered actionable insights on SQL/Python dominance, cloud trends, salary premiums and which tools are rising vs falling

If you only have a minute, review these:
1. [01_top_demanded_skills.sql](./01_top_demanded_skills.sql) - demand analysis with multi-table joins
2. [02_top_paying_skills.sql](./02_top_paying_skills.sql) - salary analysis with sample size filtering
3. [03_optimal_skills.sql](./03_optimal_skills.sql) - combined demand/salary optimization query
4. [04_skill_demand_trends.sql](./04_skill_demand_trends.sql) - year over year skill trends with CTEs and window functions

## Problem & Context
Job market analysts need to answer questions like:

- 🎯 **Most in-demand:** *Which skills are most in-demand for data engineers?*
- 💰 **Highest paid:** *Which skills command the highest salaries?*
- ⚖️ **Best trade-off:** *What is the optimal skill set balancing demand and compensation?*
- 📈 **Direction:** *Which skills are growing and which are fading?*

This project analyses a data warehouse built using a star schema design (the same warehouse I build from scratch in [Project 2](../2_DW_Mart_Build/)). The warehouse structure consists of:

![Data Warehouse](../Images/1_2_Data_Warehouse.png)

- **Fact Table:** `job_postings_fact` - Central table containing job posting details (job titles, locations, salaries, dates, etc.)
- **Dimension Tables:**
    - `company_dim` - Company information linked to job postings
    - `skills_dim` - Skills catalog with skill names and types
- **Bridge Table:** `skills_job_dim` - Resolves the many-to-many relationship between job postings and skills

By querying across these interconnected tables, I extracted insights about skill demand, salary patterns, optimal skill combinations and trends for data engineering roles.

## Tech Stack
- 🐤 **Query Engine:** DuckDB for fast OLAP-style analytical queries
- 🧮 **Language:** SQL (ANSI-style with analytical functions)
- 📊 **Data Model:** Star schema with fact + dimension + bridge tables
- 🛠️ **Development:** VS Code for SQL editing + Terminal for DuckDB CLI
- 📦 **Version Control:** Git/GitHub for versioned SQL scripts

## How to Run
1. Build the warehouse by following the steps in [Project 2](../2_DW_Mart_Build/README.md#how-to-run) (creates `dw_marts.duckdb`)
2. From this folder, run any query against it:
```bash
duckdb ../2_DW_Mart_Build/dw_marts.duckdb -c ".read 01_top_demanded_skills.sql"
```
Each file has the question at the top and the result table + my insights at the bottom.

## Analysis Overview
### Query Structure
1. **[Top Demanded Skills](./01_top_demanded_skills.sql)** – Identifies the 10 most in-demand skills for remote data engineer positions
2. **[Top Paying Skills](./02_top_paying_skills.sql)** – Analyzes the 25 highest-paying skills with salary, salary sample size and demand
3. **[Optimal Skills](./03_optimal_skills.sql)** – Calculates an optimal score using natural log of demand combined with median salary to identify the most valuable skills to learn
4. **[Skill Demand Trends](./04_skill_demand_trends.sql)** – Ranks skills per year (2023-2025) and compares ranks to find rising and falling skills

### Key Insights
- 🧠 **Core languages:** SQL (29,221) and Python (28,776) each appear in ~2 out of 3 remote data engineer postings. They're the entry ticket, not a differentiator
- ☁️ **Cloud platforms:** AWS (17,823) and Azure (14,143) are next, and Azure overtook AWS for #3 across all DE postings in 2025
- 💰 **Salary premium:** Terraform has the highest median salary ($184K) with a solid sample, and also ranks #1 on the optimal score. Kubernetes and Airflow pay ~$150K while still being in high demand
- 🔥 **Big data:** Spark is the top processing engine (12,799 remote postings, $140K median)
- 📈 **Rising:** Databricks (#10 → #6) and Snowflake (#11 → #7) climbed the most among top skills between 2023 and 2025, with PySpark (+6) not far behind
- 📉 **Falling:** Hadoop (#8 → #13) and Kafka (#7 → #12) are losing ground as teams move to managed cloud platforms
- 🗺️ **Suggested learning path:** SQL + Python → AWS/Azure → Spark + Airflow → Snowflake/Databricks, with Terraform/Kubernetes as salary boosters

### A note on salary data
Only **1,576 of 43,853** remote data engineer postings (~3.6%) include a yearly salary. When I first ranked skills by median salary, Rust came out on top at $210K, but that was based on just 23 salaries. To keep the results honest:
- `02_top_paying_skills.sql` reports `salary_sample_size` next to each median and requires at least 30 salaried postings
- `03_optimal_skills.sql` filters to salaried postings so that demand and salary are measured on the same rows
- `04_skill_demand_trends.sql` compares **rank** and **% of postings** instead of raw counts, since 2025 is a partial year and 2025 postings list fewer skills on average (5.2 vs 6.1)

## SQL Skills Demonstrated
### Query Design & Optimization
- **Complex Joins**: Multi-table `INNER JOIN` operations across `job_postings_fact`, `skills_job_dim`, and `skills_dim`
- **CTEs**: Multi-step `WITH` pipeline in the trends query to keep each transformation readable
- **Aggregations**: `COUNT()`, `MEDIAN()`, `ROUND()` for statistical analysis
- **Filtering**: Boolean logic with `WHERE` clauses and multiple conditions (`job_title_short`, `job_work_from_home`, `salary_year_avg IS NOT NULL`)
- **Sorting & Limiting**: `ORDER BY` with tie-breakers and `LIMIT` for deterministic top-N analysis

### Data Analysis Techniques
- **Grouping**: `GROUP BY` for categorical analysis by skill
- **Window Functions**: `RANK() OVER (PARTITION BY year ...)` to rank skills within each year
- **Conditional Aggregation**: `MAX(...) FILTER (WHERE ...)` to pivot years into columns
- **Mathematical Functions**: `LN()` for natural logarithm transformation to normalize demand metrics
- **Calculated Metrics**: Derived optimal score combining log-transformed demand with median salary, and % of postings per year
- **HAVING Clause**: Filtering aggregated results (minimum postings / minimum salary sample size)
- **NULL Handling**: `COUNT(column)` vs `COUNT(*)` to measure how many rows actually have a salary
