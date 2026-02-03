# Architecture Deep Dive: OpsFlow Analytics

## 1. How dbt Connects to BigQuery
You asked: *"How does dbt query BigQuery? I didn't see any connection module."*

dbt Core separates **Code** (your models) from **Configuration** (your credentials). This is a security best practice.

### The `profiles.yml`
dbt looks for a file called `profiles.yml` in your home directory (`~/.dbt/`). It is **not** stored in the project folder to prevent accidental git commits of passwords.

**Example `profiles.yml`:**
```yaml
opsflow:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: your-gcp-project-id
      dataset: opsflow_analytics_dev
      keyfile: /path/to/your/service-account.json
      threads: 4
```

### The Connection Flow
1.  **Compilation**: When you run `dbt run`, dbt reads your `dbt_project.yml` to find the profile name (`opsflow`).
2.  **Authentication**: It loads `profiles.yml`, grabs the Service Account key, and authenticates with Google Cloud via API.
3.  **Execution**: dbt compiles your SQL (resolving `{{ ref() }}` to actual table names like `gcp_project.dataset.table`) and sends the raw SQL to BigQuery to execute.

---

## 2. Infrastructure: "The dbt Engine"
You asked: *"What resource keeps the 'dbt engine' running?"*

**Crucial Concept**: dbt Core is **stateless**. There is no "dbt server" running 24/7.

### Where does it run?
-   **Storage**: 100% in **BigQuery**. dbt does not store data; it just tells BigQuery to create tables/views.
-   **Compute (Data Processing)**: 100% in **BigQuery**. When dbt sends a `CREATE TABLE AS SELECT...`, BigQuery's servers do the heavy lifting of sorting/joining millions of rows.
-   **Compute (Orchestration)**: This is the only part dbt does. It runs on a **client machine**.
    -   *In Dev*: Your laptop.
    -   *In Prod*: A transient container (e.g., GitHub Actions runner, Airflow Worker, AWS Fargate). It spins up, runs `dbt run`, and shuts down.

**Cost Implications**: You pay mainly for BigQuery (Storage + Queries). The "dbt runner" is very cheap because it only orchestrates API calls.

---

## 3. Roadmap: From Portfolio to Production
You asked: *"What are the next steps to make this a real product?"*

To turn `opsflow_analytics` into a robust enterprise solution, we would implement:

### Phase 1: Automation (CI/CD)
-   **Goal**: Remove "running from my laptop".
-   **Tool**: GitHub Actions or GitLab CI.
-   **Action**: Create a workflow `.github/workflows/dbt_run.yml` that runs `dbt build` every morning at 06:00 AM UTC.

### Phase 2: Orchestration
-   **Goal**: Handle dependencies (e.g., "Only run dbt AFTER the raw data has arrived in BigQuery").
-   **Tool**: Apache Airflow or Dagster.
-   **Action**: Create a DAG that waits for the `im_arrival_scan` file → loads to BigQuery → triggers `dbt run`.

### Phase 3: Data Quality Monitoring
-   **Goal**: Be alerted *before* the dashboard breaks.
-   **Tool**: dbt tests (basic) or Monte Carlo (advanced).
-   **Action**: Configure Slack alerts. If `assert_operational_ratios_sum_to_one` fails, the Data Engineer gets a ping immediately.

### Phase 4: Reverse ETL (Actionable Data)
-   **Goal**: Push forecasts back to the operational tools.
-   **Tool**: Hightouch or Census.
-   **Action**: Take the `mart_natural_growth_daily` table and push the predictions into the Warehouse Management System (WMS) so it auto-schedules staff.

---

## 4. Data Persistence: "Virtual vs Physical"
You asked: *"Is the Gold layer persisted? or is it just virtual/views?"*

**Answer**: In this project, the Gold Layer (Marts) is **Physically Persisted**.

### The Strategy (configured in `dbt_project.yml`)

| Layer | Materialization | State | Why? |
| :--- | :--- | :--- | :--- |
| **Staging** | `view` | Virtual | Lightweight. Always reflects raw data instantly. Zero storage cost. |
| **Intermediate** | `view` | Virtual | Chaining logic. No need to store intermediate steps unless very heavy. |
| **Marts (Gold)** | `table` | **Persisted**| **Performance & Cost**. BI tools (Metabase) query this repeatedly. |

### Why persist the Gold Layer?
1.  **Performance**: Dashboard loads instantly because it doesn't recalculate the whole history every time a user opens it.
2.  **Cost**: BigQuery charges by *bytes processed*. If `mart_natural_growth` scans 1TB of raw data to build, you don't want to pay for that 1TB scan every time a manager hits "Refresh". You calculate it once (during `dbt run`), save the result (tiny table), and the manager queries the tiny table cheaply.
3.  **Snapshotting**: Tables provide a stable "truth" for that day, whereas views might change if underlying raw data changes.

---

## 5. Storage Internals: "Is it a Relational Database?"
You asked: *"Where is this physical table stored? Is it like a relational database?"*

**Answer**: It is stored in Google's proprietary file system (**Colossus**), but **NO**, it is not a traditional operational relational database (like PostgreSQL or MySQL).

### Key Differences (The "Interview Answer")

| Feature | Traditional RDBMS (Postgres/MySQL) | Modern Data Warehouse (BigQuery) |
| :--- | :--- | :--- |
| **Storage Format** | **Row-Oriented** (B-Tree). Good for fetching one user's profile. | **Columnar** (Capacitor). Good for summing `orders_count` for 10 million rows. |
| **Physical Location** | Local SSD/Disk attached to the server. | Distributed File System (Colossus). Decoupled from Compute. |
| **Constraints** | Enforces Primary Keys/Foreign Keys strictly. | **Does NOT enforce** PK/FKs. Constraints are informative only. |

### Where is the file?
There is no single `.mdf` or `.db` file.
When dbt runs `CREATE TABLE`, BigQuery takes your data, shreds it into columns, compresses it aggressively, and spreads it across thousands of Google hard drives in a specific region (e.g., `us-east1`).
It presents it to you *looking* like a SQL table, but under the hood, it is a massive distributed file dataset tailored for aggregation speed.


