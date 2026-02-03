
-- Test that daily operational ratios sum to approximately 1.0 (100%)
-- Tolerance of 0.01 for floating point math
with validation as (
    select
        pickup_date,
        client_type,
        business_type,
        sum(daily_ratio) as total_ratio
    from {{ ref('int_operational_ratios') }}
    group by 1, 2, 3
)

select *
from validation
where total_ratio < 0.99 or total_ratio > 1.01
