
{{ config(materialized='table') }}

/*
Goal: 
    - Create a dimension table for geography that includes country-level attributes such as country name, region, and sub-region.
    - This will allow for analysis of streaming performance by geography and enable joining with the fact_streams table on country_code.
Granularity:
    - One record per unique country, identified by country_code.
*/

SELECT
    country_code,
    country_name,
    region,
    sub_region
FROM {{ ref('geography_data') }}