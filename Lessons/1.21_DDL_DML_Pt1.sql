/* 
To run this script,
.read Lessons\1.21_DDL_DML_Pt1.sql

*/

CREATE IF NOT EXISTS DATABASE job_mart;

SHOW DATABASES;

/*
If, for example, you had an automation script you were trying to run to create a database,

CREATE DATABASE IF NOT EXISTS job_mart; This prevents the error if already exists
*/

-- DROP DATABASE job_mart;
-- DROP DATABASE IF EXISTS job_mart;


CREATE SCHEMA job_mart.staging; --If you don't specify the database, the schema willbe created in the database you logged in with.
-- CREATE SCHEMA IF NOT EXISTS job_mart.staging

DROP SCHEMA job_mart.staging;

-- Can declare the use of your job_mart databases so that you don't have to type job_mart everywhere.
USE job_mart;
CREATE SCHEMA IF NOT EXISTS staging;

SELECT
    *
FROM information_schema.schemata;

CREATE TABLE IF NOT EXISTS staging.preferred_roles (
    role_id INTEGER PRIMARY KEY,
    role_name VARCHAR
);

-- DROP TABLE IF EXISTS <schema_name>.<table_name>;

SELECT *
FROM information_schema.tables
WHERE table_catalog = 'job_mart';


INSERT INTO staging.preferred_roles (role_id, role_name)
VALUES 
    (1, 'Data Engineer'),
    (2, 'Senior Data Engineer');

INSERT INTO staging.preferred_roles (role_id, role_name)
VALUES
    (3, 'Software Engineer');

SELECT *
FROM staging.preferred_roles;

ALTER TABLE staging.preferred_roles
ADD COLUMN preferred_role BOOLEAN;

/*
ALTER TABLE staging.preferred_roles
DROP COLUMN preferred_role;
*/ 

UPDATE staging.preferred_roles
SET preferred_role = TRUE
WHERE role_id =1 OR role_id = 2;

UPDATE staging.preferred_roles
SET preferred_role = FALSE
WHERE role_id = 3;

ALTER TABLE staging.preferred_roles
RENAME TO priority_roles;

SELECT *
FROM staging.priority_roles;

ALTER TABLE staging.priority_roles
RENAME COLUMN preferred_role TO priority_lvl;

-- Priority level set from 1 to 3
ALTER TABLE staging.priority_roles
ALTER COLUMN priority_lvl TYPE INTEGER;

UPDATE staging.priority_roles
SET priority_lvl = 3
WHERE role_id = 3;

SELECT *
FROM staging.priority_roles;

