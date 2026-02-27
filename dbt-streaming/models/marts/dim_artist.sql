{{ config(materialized='table') }}

/*
Goal: 
    - Create a dimension table for artists that includes artist-level attributes such as artist name.
    - This will allow for analysis of streaming performance by artist and enable joining with the fact_streams table on artist_key.
Granularity:
    - One record per unique artist, identified by artist_key.
*/

SELECT DISTINCT
    artist_key,
    NULL AS artist_name -- This data is not available at source but kept as a placeholder for future enrichment
FROM {{ ref('int_streams') }}
WHERE artist_key IS NOT NULL