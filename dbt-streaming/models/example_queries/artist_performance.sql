-- rpt_artist_performance

{{ config(materialized='table') }}

SELECT
    f.artist_key,
    f.date_key,
    d.year_number,
    d.quarter_number,
    d.month_number,
    p.platform,
    g.country_code,
    g.country_name,
    g.region,
    SUM(f.streams_artist) AS streams,
    COUNT(DISTINCT f.track_key) AS unique_tracks_streamed
FROM {{ ref('fact_streams') }} AS f
INNER JOIN {{ ref('dim_date') }} AS d ON f.date_key = d.date_key
INNER JOIN {{ ref('dim_platform') }} AS p ON f.platform_key = p.platform_key
INNER JOIN {{ ref('dim_geography') }} AS g ON f.country_code = g.country_code
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
