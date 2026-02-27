{{ config(materialized='table') }}

/*
Goal: 
    - Create a fact table that aggregates streaming data at the track, artist, label, country, and date level across all platforms.
    - This will allow for comprehensive analysis of streaming performance across different dimensions.
Granularity:
    - One record per unique combination of platform, date, track, track_title, artist, label, and country.
*/

SELECT
    _surrogate_key, -- Primary key
    date_key, -- Foreign key to dim_date
    platform_key, -- Foreign key to dim_platform
    song_id, -- Song ID, null for YouTube records
    track_key, -- Foreign key to dim_track
    release_id, -- Release ID, null for YouTube records
    youtube_video_id, -- YouTube video ID, specific to YouTube records
    youtube_cms, -- YouTube CMS, specific to YouTube records
    artist_key, -- Foreign key to dim_artist
    label_key, -- Foreign key to dim_label
    country_code, -- Foreign key to dim_geography
    streams_track,
    streams_artist,
    streams_label
FROM {{ ref('int_streams') }}