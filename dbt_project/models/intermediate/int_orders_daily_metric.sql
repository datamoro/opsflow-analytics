
with staging as (
    select * from {{ ref('stg_im_global_collect_rate') }}
),

daily_aggregation as (
    select
        created_date,
        client_normalized as client_type,
        business_type_normalized as business_type,
        count(waybill_id) as orders_count
    from staging
    group by 1, 2, 3
)

select 
    *,
    -- Deriving weekday for analysis
    FORMAT_DATE('%a', created_date) as weekday_name,
    EXTRACT(DAYOFWEEK FROM created_date) as weekday_num
from daily_aggregation
