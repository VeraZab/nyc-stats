SELECT
    *
FROM
    {{ source(
        'staging',
        'my_table'
    ) }}
LIMIT
    10
