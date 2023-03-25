SELECT
    DISTINCT unique_key,
    created_date,
    closed_date,
    UPPER(agency) AS agency,
    agency_name,
    LOWER(complaint_type) AS complaint_type,
    descriptor,
    latitude,
    longitude,
FROM
    {{ source(
        'staging',
        'my_table'
    ) }}
