
{{ config(materialized='table') }}

/*
Goal: 
    - Create a dimension table for platforms that includes platform-level attributes such as platform name.
    - This will allow for analysis of streaming performance by platform and enable joining with the fact_streams table on platform_key.
Granularity:
    - One record per unique platform, identified by platform_key.
*/

SELECT DISTINCT
    platform_key,
    platform
FROM {{ ref('int_streams') }}
WHERE platform_key IS NOT NULL