-- rpt_track_performance
-- Uses streams_track exclusively. Never streams_artist or streams_label.

{{ config(materialized='table') }}

SELECT
    f.track_key,
    t.track_title,
    f.song_id,
    f.release_id,
    f.date_key,
    d.year_number,
    d.month_number,
    p.platform,
    g.country_code,
    g.country_name,
    SUM(f.streams_track) AS streams,
    COUNT(DISTINCT f.artist_key) AS artist_count
FROM {{ ref('fact_streams') }} AS f
INNER JOIN {{ ref('dim_track') }} AS t ON f.track_key = t.track_key
INNER JOIN {{ ref('dim_date') }} AS d ON f.date_key = d.date_key
INNER JOIN {{ ref('dim_platform') }} AS p ON f.platform_key = p.platform_key
INNER JOIN {{ ref('dim_geography') }} AS g ON f.country_code = g.country_code
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
