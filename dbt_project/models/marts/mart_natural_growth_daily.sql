
with daily_metric as (
    select * from {{ ref('int_orders_daily_metric') }}
),

lagged_metrics as (
    select
        created_date,
        client_type,
        business_type,
        orders_count as current_volume,
        weekday_name,
        
        -- Previous day's volume for growth calc
        LAG(orders_count) OVER (
            PARTITION BY client_type, business_type 
            ORDER BY created_date
        ) as prev_day_volume

    from daily_metric
)

select
    created_date,
    client_type,
    business_type,
    weekday_name,
    current_volume,
    prev_day_volume,
    
    -- Growth Calculation
    CASE 
        WHEN prev_day_volume > 0 THEN current_volume / prev_day_volume 
        ELSE 0 
    END as growth_rate,
    
    'Natural Growth' as metric_category

from lagged_metrics
order by created_date desc, client_type
