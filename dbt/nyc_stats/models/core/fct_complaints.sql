{{ config(
    materialized = "table",
    partition_by ={ "field": "created_date",
    "data_type": "timestamp",
    "granularity": "month" },
    cluster_by = ["complaint_type", "agency"]
) }}

SELECT
    *
FROM
    {{ ref('stg_my_table') }}
WHERE
    latitude IS NOT NULL
    AND longitude IS NOT NULL
