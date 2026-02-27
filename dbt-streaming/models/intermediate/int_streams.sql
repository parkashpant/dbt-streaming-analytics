{{ config(materialized='table') }}

/*
Goal: 
    - Prepare a clean, unified streaming performance dataset for tracks, artists, and labels across different platforms.

Granularity:
    - One record per unique combination of platform, date, track, track_title, artist, label, and country.

Inferences and assumptions:
    - The source data shows multiple records for each track based on the number of artists and country the track is streamed
      in. This is mostly true for other platforms except YouTube where same track can have different labels as well inflating
      the number of records for the same track even more.

    - The streams_artist count represents the stream count for each artist associated with a track whereas streams_track 
      represents the stream count for the track itself. However, my assumption is that upstream the streams_track is
      calculated by dividing streams_artists for a track by the number of artists associated with the track to avoid double
      counting streams for tracks with multiple artists. The same is applicable for streams_label except in YouTube where the 
      streams_label has given different weightage compared to streams_track.

    - For Spotify, there are duplicate records even for the same track, artist, label, country, and date with different stream counts.
      It could be how source receiving data for spotify is structured. In any case, we want to aggregate those records at the 
      appropriate level before unioning with other platforms.

    - For YouTube, there are separate fields such as youtube_video_id and youtube_video_title in place of track related fields and
      this needs to be mapped to the same format as other platforms for union. 
      Additionally, some YouTube records have missing youtube_video_title, but we will keep those records as they still have artist
      and label information and stream counts that can be useful for analysis at the artist and label level even if track-level 
      analysis is not possible. 
*/

WITH streams AS (
    SELECT * FROM {{ ref('stg_streams') }}
),

-- TikTok, Amazon, and Spotify:
-- Aggregate stream count since source data for Spotify contains some duplicates rows with additional counts
-- We will aggregate the stream count at the level of unique combinations of platform, date, track, artist,
-- label, and country to align with the granularity we want in our final model.
agg_streams_songs AS (
    SELECT
        platform,
        date,
        song_id,
        track_id,
        track_title,
        release_id,
        NULL AS youtube_video_id, -- No equivalent field for non-YouTube platforms, set to null
        NULL AS youtube_cms, -- No equivalent field for non-YouTube platforms, set to null
        artist_id,
        label_account_name AS label_name,
        country_code,
        SUM(streams_track) AS streams_track,
        SUM(streams_artist) AS streams_artist,
        SUM(streams_label) AS streams_label
    FROM streams
    WHERE platform IN ('TikTok', 'Amazon', 'Spotify')
    GROUP BY
        platform,
        date,
        song_id,
        track_id,
        track_title,
        release_id,
        artist_id,
        label_account_name,
        country_code
),

-- YouTube:
-- Map youtube data to the same format as above for union. 
-- There are some duplicate YouTube records with the same youtube_video_id, artist_id, label_account_name,
-- country_code, and date but different stream counts. We will aggregate the stream counts for those records as well.
agg_streams_youtube AS (
    SELECT
        streams.platform,
        streams.date,
        NULL AS song_id, -- No equivalent field for YouTube, set to null
        {{ dbt_utils.generate_surrogate_key(['streams.youtube_video_id', 'streams.youtube_cms']) }} AS track_id, -- Map youtube_video_id and youtube_cms as track_id for consistency with other platforms
        streams.youtube_video_title AS track_title, -- Mapping youtube_video_title to track_title for consistency, even though it is not consistently populated 
        NULL AS release_id, -- No equivalent field for YouTube, set to null
        streams.youtube_video_id,
        streams.youtube_cms,
        streams.artist_id,
        COALESCE(streams.label_account_name, 'Unknown Label') AS label_name, -- Populate missing label_account_name values with 'Unknown Label'
        COALESCE(streams.country_code, geography.country_code) AS country_code, -- Populate missing country_code with geography data
        SUM(streams_track) AS streams_track,
        SUM(streams_artist) AS streams_artist,
        SUM(streams_label) AS streams_label
    FROM streams
    -- Join geography data to get country codes for YouTube records where country is reported but country_code is null.
    LEFT JOIN {{ ref('geography_data') }} AS geography
        ON streams.country = geography.country_name
    WHERE platform = 'YouTube'
    GROUP BY
        streams.platform,
        streams.date,
        track_id,
        streams.youtube_video_title,
        streams.youtube_video_id,
        streams.youtube_cms,
        streams.artist_id,
        COALESCE(streams.label_account_name, 'Unknown Label'),
        COALESCE(streams.country_code, geography.country_code)
),

unioned AS (
    SELECT * FROM agg_streams_songs
    UNION ALL
    SELECT * FROM agg_streams_youtube
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'platform', 'date', 'track_id', 'track_title',
        'artist_id', 'label_name', 'country_code'
    ]) }} AS _surrogate_key, -- This will unique identify each record in our final model and can be used as a primary key
    {{ dbt_utils.generate_surrogate_key(['platform',]) }} AS platform_key,
    platform,
    date AS date_key,
    song_id,
    track_id AS track_key,
    track_title,
    release_id,
    youtube_video_id,
    youtube_cms,
    artist_id AS artist_key,
    {{ dbt_utils.generate_surrogate_key(['label_name']) }} AS label_key,
    label_name,
    country_code,
    streams_track,
    streams_artist,
    streams_label
FROM unioned
