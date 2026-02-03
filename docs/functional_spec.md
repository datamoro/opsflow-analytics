# Functional Specification: OpsFlow Analytics

## 1. Product Overview
**Product Name**: OpsFlow Analytics  
**Goal**: Automate the calculation of operational demand forecasts for logistics planning.  
**Users**: Operations Managers, Supply Chain Analysts.

## 2. User Personas
### 2.1 Logistics Manager
- **Goal**: Ensure sufficient staffing (drivers/warehouse) for the next 7 days.
- **Pain Point**: Manual Excel spreadsheets are error-prone and late.
- **Requirement**: "I need to wake up and see the predicted volume for tomorrow by 8:00 AM."

### 2.2 Shift Supervisor (CDC)
- **Goal**: Organize sorting shifts based on incoming volume distribution.
- **Requirement**: "I need to know if the volume is coming in the Morning (T1) or Evening (T2) shift."

## 3. Functional Requirements

### FR1: Data Ingestion
- **FR1.1**: The system must ingest raw order data (`im_global_collect_rate`) and scan data (`im_arrival_scan`) daily.
- **FR1.2**: Data must be standardized (Client Names mapped to canonical types like 'Client_A', 'Client_B').

### FR2: Metric Calculation
- **FR2.1 - Natural Growth**: Calculate Day-over-Day growth rate grouped by Weekday logic (e.g., this Monday vs last Monday).
- **FR2.2 - Operational Ratios**: Calculate the percentage of orders picked up on T+0, T+1, etc.
- **FR2.3 - Shift Distribution**: Calculate the splits between Morning (T1) and Evening (T2) shifts based on historical efficiency.

### FR3: Forecasting (Future Scope)
- **FR3.1**: Apply calculated Growth Rates and Ratios to current backlog to predict future volume (Consolidated Forecast).

### FR4: Data Quality & Reliability
- **FR4.1**: Growth rates must definitely not be negative unless specified.
- **FR4.2**: Ratios (percentages) for a given day must sum to 1.0 (100%).

## 4. Non-Functional Requirements
- **NFR1 - Latency**: Daily pipeline must complete by 07:00 AM local time.
- **NFR2 - History**: System must maintain at least 90 days of historical data for trend analysis.
- **NFR3 - Scalability**: Must handle up to 1M orders/day without refactoring.

## 5. Success Metrics
- **Automated Coverage**: 100% replacement of manual Excel report.
- **Incident Rate**: < 1 data quality issue per week.
