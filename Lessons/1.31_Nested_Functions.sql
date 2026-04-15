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


WITH skill_table AS (
    SELECT 'python' AS skills, 'programming' AS types
    UNION ALL
    SELECT 'sql', 'query_language'
    UNION ALL
    SELECT 'r', 'programming'
)
SELECT
    STRUCT_PACK(
        skill := skills,
        type := types
    )
FROM skill_table;

--Array of structs
SELECT [
    {skill: 'python', type:'programming'},
    {skill: 'sql', type: 'query_langugae'}
] AS skills_array_of_structs;

WITH skill_table AS (
    SELECT 'python' AS skills, 'programming' AS types
    UNION ALL
    SELECT 'sql', 'query_language'
    UNION ALL
    SELECT 'r', 'programming'
), skills_array_struct AS (
    SELECT
        ARRAY_AGG(
                STRUCT_PACK(
                skill := skills,
                type := types
            )
        ) AS array_struct
FROM skill_table
)

SELECT
    array_struct[1].skill,
    array_struct[2].type,
    array_struct[3]
FROM skills_array_struct;

--MAP
WITH skill_map AS (
    SELECT MAP {'skill': 'python', 'type': 'programming'} AS skill_type
)
SELECT
    skill_type['skill'],
    skill_type['type']
FROM skill_map;

--JSON
WITH raw_skill_json AS (
    SELECT
        '{"skill":"python", "type":"programming"}'::JSON AS skill_json
)
SELECT
    STRUCT_PACK(
        skill := json_extract_string(skill_json, '$.skill'),
        type := json_extract_string(skill_json, '$.type')
    )
FROM raw_skill_json;

--JSON to Array of Struct
WITH raw_json AS (
    SELECT
    '[
        {"skill":"python", "type":"programming"},
        {"skill":"sql", "type":"query_language"},
        {"skill":"r", "type":"programming"}
    ]' :: JSON AS skills_json
)
SELECT
    ARRAY_AGG(
        STRUCT_PACK(
            skill := json_extract_string(e.value, '$.skill'),
            type := json_extract_string(e.value, '$.type')
        )
        ORDER BY json_extract_string(e.value, '$.skill')
    ) AS skills
FROM raw_json, json_each(skills_json) AS e;