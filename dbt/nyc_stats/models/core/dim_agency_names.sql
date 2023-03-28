{{ config(
    materialized = 'table'
) }}

SELECT
    *
FROM
    {{ ref('agencies') }}
