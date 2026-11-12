# sql-transactional-reconciliation
SQL scripts for transactional batch reconciliation, duplicate detection, and SLA audit reporting (PostgreSQL / Oracle).
# 🗄️ Transactional Batch Reconciliation & Audit Queries (SQL)

Production-oriented SQL scripts designed for post-batch reconciliation, financial integrity verification, and operational SLA reporting across relational databases (**PostgreSQL / Oracle DB**).

## 🚀 Covered Scenarios
- **Schema Design & Constraints:** Transactional ledger table with primary keys, currency checks, and audit timestamps.
- **Duplicate & Anomaly Detection:** Window functions (`ROW_NUMBER`) and grouping queries to flag duplicate batch entries or out-of-range amounts.
- **Daily Settlement Summary:** Aggregated reconciliation reports grouped by currency (`PYG`, `USD`) and processing status (`APPROVED`, `REJECTED`, `PENDING`).
- **SLA & Latency Monitoring:** Queries to identify delayed batch jobs exceeding processing thresholds.

## 🛠️ Compatibility
- PostgreSQL 14+ / Oracle Database 19c+
