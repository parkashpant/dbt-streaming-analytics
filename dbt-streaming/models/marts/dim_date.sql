{{ config(materialized='table') }}

/*
Goal: 
    - Create a dimension table for date that includes various date attributes such as day, week, month, quarter, and year.
    - This will allow for analysis of streaming performance by different date attributes and enable joining with the fact_streams table on date_key.
Granularity:
    - One record per unique date, identified by date_key.
*/


WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="CURRENT_DATE"
    ) }}
),

final AS (
    SELECT
        -- day
        date_day::DATE AS date_key,
        EXTRACT(DAY FROM date_day)::INT AS day_of_month,
        EXTRACT(DOY FROM date_day)::INT AS day_of_year,
        EXTRACT(DOW FROM date_day)::INT AS day_of_week,
        TO_CHAR(date_day, 'Day') AS day_name,

        -- week
        EXTRACT(WEEK FROM date_day)::INT AS week_of_year,
        DATE_TRUNC('week', date_day)::DATE AS week_start_date,

        -- month
        EXTRACT(MONTH FROM date_day)::INT AS month_number,
        TO_CHAR(date_day, 'Month') AS month_name,
        TO_CHAR(date_day, 'Mon') AS month_name_short,
        DATE_TRUNC('month', date_day)::DATE AS month_start_date,

        -- quarter
        EXTRACT(QUARTER FROM date_day)::INT AS quarter_number,
        'Q' || EXTRACT(QUARTER FROM date_day) AS quarter_name,
        DATE_TRUNC('quarter', date_day)::DATE AS quarter_start_date,

        -- year
        EXTRACT(YEAR FROM date_day)::INT AS year_number,
        DATE_TRUNC('year', date_day)::DATE  AS year_start_date
    FROM date_spine
)

SELECT * FROM final