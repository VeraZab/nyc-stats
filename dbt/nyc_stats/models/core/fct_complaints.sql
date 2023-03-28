{{ config(
    materialized = "table",
    partition_by ={ "field": "created_date",
    "data_type": "timestamp",
    "granularity": "month" },
    cluster_by = ["complaint_type", "agency_name"]
) }}

WITH dim_agencies AS (

    SELECT
        *
    FROM
        {{ ref('dim_agency_names') }}
),
complaints AS (
    SELECT
        *
    FROM
        {{ ref('stg_my_table') }}
)
SELECT
    complaints.unique_key,
    complaints.created_date,
    complaints.closed_date,
    COALESCE(
        dim_agencies.full_name,
        complaints.agency
    ) AS agency_name,
    complaints.complaint_type,
    complaints.descriptor,
    complaints.incident_zip,
FROM
    complaints
    LEFT OUTER JOIN dim_agencies
    ON complaints.agency = dim_agencies.abbreviation
