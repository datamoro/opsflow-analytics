
with source as (
    select * from {{ source('raw_source', 'im_arrival_scan') }}
),

renamed as (
    select
        waybillNo as waybill_id,
        scanDate as scan_at,
        date(scanDate) as scan_date,
        scanStation as scan_station_raw,
        
        -- Dimensions
        clientName as client_name_scan,
        
        -- Derived
        EXTRACT(HOUR FROM scanDate) as scan_hour

    from source
)

select * from renamed
