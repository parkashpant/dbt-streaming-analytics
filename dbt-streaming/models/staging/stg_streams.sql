{{ config(materialized='table') }}

-- This model performs basic data hygiene and keep model identical to source for ease of debugging and validation.

WITH source AS (
    SELECT
        platform,
        youtube_cms,
        youtube_video_id,
        youtube_video_title,
        CAST(date AS DATE) AS date,
        song_id,
        track_title,
        CAST(track_id AS VARCHAR) AS track_id,
        CAST(release_id AS VARCHAR) AS release_id,
        CAST(artist_id AS VARCHAR) AS artist_id,
        label_account_name,
        streams_track,
        streams_artist,
        streams_label,
        tiktok_creations_track,
        tiktok_creations_artist,
        tiktok_creations_label,
        country_code,
        country,
        region
    FROM {{ ref('sample_data') }} 
),

-- Filter out rows with NULL values in critical columns
filter_source AS (
    SELECT *
    FROM source
    WHERE
        platform IS NOT NULL
        AND (youtube_video_id IS NOT NULL OR track_id IS NOT NULL)
        AND artist_id IS NOT NULL
        AND date IS NOT NULL
)

SELECT * FROM filter_source
