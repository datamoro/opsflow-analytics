
-- Test that natural growth rates are within "sane" business bounds
-- It is very unlikely for day-over-day growth to be negative (< 0) or massive (> 500% aka 5.0) 
-- unless it's a special promo day. This warn test catches anomalies.

select
    *
from {{ ref('mart_natural_growth_daily') }}
where growth_rate < 0 
   or growth_rate > 5.0
