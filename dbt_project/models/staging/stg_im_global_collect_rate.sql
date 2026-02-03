
with source as (
    select * from {{ source('raw_source', 'im_global_collect_rate') }}
),

renamed as (
    select
        -- IDs
        waybillNo as waybill_id,
        
        -- Timestamps
        date(createDate) as created_date,
        createDate as created_at,
        pickupTime as pickup_at,
        date(pickupTime) as pickup_date,

        -- Dimensions
        clientName as client_name_raw,
        businessType as business_type_raw,
        
        -- Logic from SQL (Client Normalization)
        CASE
            WHEN clientName NOT IN ('Client_B', 'Client_C', 'Client_A D2D', 'Client_A W2D', 'Client_A FM', 'Client_A CROSS BORDER') THEN 'Regional_Sales'
            WHEN clientName LIKE 'Client_A%' THEN 'Client_A'
            WHEN clientName LIKE 'Client_B' THEN 'Client_B'
            ELSE clientName
        END AS client_normalized,
        
        CASE
            WHEN clientName NOT IN ('Client_B', 'Client_C', 'Client_A D2D', 'Client_A W2D', 'Client_A FM', 'Client_A CROSS BORDER')
                 AND businessType IN ('W2D', 'FM', 'CROSS BORDER') THEN 'D2D'
            WHEN businessType = 'CROSS BORDER' THEN 'CB'
            ELSE businessType
        END AS business_type_normalized,

        -- Derived derived columns
        DATE_DIFF(DATE(pickupTime), DATE(createDate), DAY) as days_to_pickup,
        EXTRACT(HOUR FROM pickupTime) as pickup_hour


    from source
    where clientName <> 'TEST'
)

select * from renamed
