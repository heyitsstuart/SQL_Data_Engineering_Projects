--Array
SELECT ['python', 'sql', 'r'] AS skills_array;

WITH skills AS (
    SELECT 'python' AS skill
    UNION ALL
    SELECT 'sql'
    UNION ALL
    SELECT 'r'
), skills_array AS (
    SELECT ARRAY_AGG(skill ORDER BY skill) AS skills -- These functions are affected by ordering so you need to specify the order
    FROM skills
)
SELECT
    skills[1] AS first_skill,
    skills[2] AS second_skill,
    skills[1] AS third_skill
FROM skills_array;


--Struct
SELECT {skill:'python', type:'Programming'} AS skill_struct;

WITH skills_struct AS (
    SELECT
        STRUCT_PACK(
            skill := 'python',
            type := 'programming'
        ) AS s
)
SELECT 
    s.skill,
    s.type    
FROM skills_struct;

