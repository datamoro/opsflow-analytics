# OpsFlow Analytics (Portfolio Project)

**Concept**: A data product for operational demand forecasting.
**Stack**: BigQuery + dbt + Metabase.

## Structure
- `dbt_project/`: Transformation logic (ELT)


## Models
- **Staging**: `base` tables from BigQuery (`stg_im_global_collect_rate`, `stg_im_arrival_scan`).
- **Intermediate**:
  - `int_natural_growth`: Daily volume and DoD growth calculations.
  - `int_operational_ratios`: Pickup and Receipt (D2D/W2D) distributions.
  - `int_cdc_ratios`: CDC Production and Operational distributions.
- **Marts**: 
  - `mart_natural_growth_daily`: Final consumption table for Growth analysis.

## Documentation
- [Functional Specifications](docs/functional_spec.md)
- [Test Cases](docs/test_cases.md)

## How to Run
1. Configure `profiles.yml` with your BigQuery credentials.
2. Run `dbt deps` to install packages (if any).
3. Run `dbt build` to execute models and tests.


