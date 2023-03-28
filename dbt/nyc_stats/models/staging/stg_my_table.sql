SELECT
    DISTINCT unique_key,
    created_date,
    closed_date,
    agency,
    LOWER(complaint_type) AS complaint_type,
    descriptor,
    CAST(
        incident_zip AS INTEGER
    ) AS incident_zip,
FROM
    {{ source(
        'staging',
        'my_table'
    ) }}
WHERE
    incident_zip BETWEEN 10001
    AND 10282
    OR incident_zip BETWEEN 10451
    AND 10475
    OR incident_zip BETWEEN 11201
    AND 11256
    OR incident_zip BETWEEN 11001
    AND 11499
    OR incident_zip BETWEEN 10301
    AND 10314
