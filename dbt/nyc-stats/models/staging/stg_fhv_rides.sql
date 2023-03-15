select * from {{ source('staging', 'fhv_taxi_rides_template') }}
limit 10