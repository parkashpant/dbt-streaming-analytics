{{ config(materialized='table') }}

/*
Goal: 
    - Create a dimension table for labels that includes label-level attributes such as label name.
    - This will allow for analysis of streaming performance by label and enable joining with the fact_streams table on label_key.
Granularity:
    - One record per unique label, identified by label_key.
*/

SELECT DISTINCT
    label_key,
    label_name
FROM {{ ref('int_streams') }}
WHERE label_key IS NOT NULL