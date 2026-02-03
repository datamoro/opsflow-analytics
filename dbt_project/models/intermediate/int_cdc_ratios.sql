
with scans as (
    select * from {{ ref('stg_im_arrival_scan') }}
    where scan_station_raw = 'CDC-SP'
),

orders as (
    select * from {{ ref('stg_im_global_collect_rate') }}
),

joined as (
    select
        s.scan_date,
        s.scan_at,
        s.scan_hour,
        o.client_normalized as client_type,
        o.pickup_date,
        
        -- Time Period Calc (Scan vs Pickup)
        DATE_DIFF(s.scan_date, o.pickup_date, DAY) as days_diff,
        
        s.waybill_id
        
    from scans s
    left join orders o on s.waybill_id = o.waybill_id
    where o.created_date >= '2025-01-01' -- Partition pruning assumption
),

distribution as (
    select
        scan_date,
        client_type,
        
        -- Time Period Bucket
        CASE 
            WHEN days_diff = 0 THEN 'T'
            WHEN days_diff = 1 THEN 'T-1'
            WHEN days_diff = 2 THEN 'T-2'
            WHEN days_diff = 3 THEN 'T-3'
            ELSE 'Others'
        END as time_period,
        
        -- Shift Bucket
        CASE
            WHEN scan_hour BETWEEN 6 AND 13 THEN 'T1'
            WHEN scan_hour BETWEEN 14 AND 21 THEN 'T2'
            ELSE 'T3'
        END as shift_name,
        
        count(distinct waybill_id) as scan_count

    from joined
    group by 1, 2, 3, 4
)

select
    *,
    FORMAT_DATE('%a', scan_date) as weekday_name,
    
    -- Production Ratio (Overall per shift)
    scan_count / SUM(scan_count) OVER (PARTITION BY scan_date, shift_name) as production_ratio,
    
    -- Op Ratio (Per Client per shift)
    scan_count / SUM(scan_count) OVER (PARTITION BY scan_date, client_type, shift_name) as op_ratio

from distribution
