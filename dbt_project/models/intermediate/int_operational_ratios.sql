
with staging as (
    select * from {{ ref('stg_im_global_collect_rate') }}
),

base_distribution as (
    select
        pickup_date,
        client_normalized as client_type,
        business_type_normalized as business_type,
        
        -- Time Period Bucket (T, T-1...)
        CASE 
            WHEN days_to_pickup = 0 THEN 'T'
            WHEN days_to_pickup = 1 THEN 'T-1'
            WHEN days_to_pickup = 2 THEN 'T-2'
            WHEN days_to_pickup = 3 THEN 'T-3'
            WHEN days_to_pickup = 4 THEN 'T-4'
            ELSE 'Others'
        END as time_period,
        
        -- Shift Bucket
        CASE
            WHEN pickup_hour BETWEEN 6 AND 13 THEN 'T1'
            WHEN pickup_hour BETWEEN 14 AND 21 THEN 'T2'
            ELSE 'T3'
        END as shift_name,
        
        count(waybill_id) as orders_count
        
    from staging
    where pickup_date is not null
    group by 1, 2, 3, 4, 5
)

select
    *,
    FORMAT_DATE('%a', pickup_date) as weekday_name,
    
    -- Calculate Ratios Window Function
    orders_count / SUM(orders_count) OVER (PARTITION BY pickup_date, client_type, business_type) as daily_ratio,
    
    -- Calculate Shift Ratio (if needed for specific shift analysis)
    orders_count / SUM(orders_count) OVER (PARTITION BY pickup_date, client_type, business_type, shift_name) as shift_ratio
    
from base_distribution
