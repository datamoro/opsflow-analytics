# Test Cases: OpsFlow Analytics

## 1. Unit Tests (dbt schema tests)

| Test ID | Model | Column | Type | Success Criteria |
| :--- | :--- | :--- | :--- | :--- |
| **UT-01** | `stg_im_global_collect_rate` | `waybill_id` | Unique | All IDs are unique. |
| **UT-02** | `stg_im_global_collect_rate` | `created_date` | Not Null | Every order has a creation date. |
| **UT-03** | `int_orders_daily_metric` | `client_type` | Accepted Values | Must be one of: ['Client_A', 'Client_B', 'Client_C', 'Regional_Sales']. |

## 2. Business Logic Tests (Data Quality)

| Test ID | Metric | Logic | SQL Check (Conceptual) |
| :--- | :--- | :--- | :--- |
| **BL-01** | Operations Ratio | Sum of daily ratios = 100% | `sum(daily_ratio) where date=X should be 1.0 ± 0.01` |
| **BL-02** | Natural Growth | Valid Range | Growth value should typically be between 0.5 (-50%) and 2.0 (+100%). Unexpected spikes > 500% should warn. |
| **BL-03** | Shifts | Coverage | Every scan must be assigned to a Shift (T1, T2, T3) - no nulls allowed. |

## 3. User Acceptance Testing (UAT)

| UAT ID | Scenario | Steps | Expected Result |
| :--- | :--- | :--- | :--- |
| **UAT-01** | Dashboard Load | Open "OpsFlow Executive" dashboard in Metabase. | Dashboard loads in < 5 seconds. Data is up to yesterday. |
| **UAT-02** | Data Consistency | Compare "Yesterday's Volume" on Dashboard vs Source System. | Variance < 0.1%. |
| **UAT-03** | Drill Down | Filter Dashboard by "Client_A". | Charts update to show only Client_A volume and ratios. |
