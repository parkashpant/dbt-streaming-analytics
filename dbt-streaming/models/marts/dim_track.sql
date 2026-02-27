{{ config(materialized='table') }}

/*
Goal: 
    - Create a dimension table for tracks that includes track-level attributes such as track title.
    - This will allow for analysis of streaming performance at the track level and enable joining with the fact_streams table on track_key.
Granularity:
    - One record per unique track, identified by track_key.
*/

SELECT DISTINCT
    track_key,
    track_title
FROM {{ ref('int_streams') }}
WHERE track_key IS NOT NULL