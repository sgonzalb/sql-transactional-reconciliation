# sql-transactional-reconciliation
SQL scripts for transactional batch reconciliation, duplicate detection, and SLA audit reporting (PostgreSQL / Oracle).
# 🗄️ Transactional Batch Reconciliation & DML Operations (SQL)

Production-oriented SQL scripts demonstrating full data lifecycle management (**DDL, DML, Transactional Control, Reconciliation & Audit Logging**) across relational databases (**PostgreSQL / Oracle DB**).

## 🚀 Covered SQL Operations
- **DDL & Constraints (`CREATE TABLE`, `INDEX`):** Transactional ledger and audit log tables with primary keys, `CHECK` constraints, and composite indexes.
- **DML & Safe Execution (`INSERT`, `UPDATE`, `DELETE`):** Controlled batch approvals, reprocessing of rejected records, and safe test-data cleanup wrapped in `BEGIN / COMMIT / ROLLBACK` transaction blocks.
- **Duplicate Prevention (`CTE` & `ROW_NUMBER`):** Window functions used inside `UPDATE` subqueries to prevent approving duplicate entries.
- **Reconciliation & Audit Reporting (`LEFT JOIN`, `GROUP BY`):** Aggregated daily settlement summaries linked to audit execution logs.

## 🛠️ Compatibility
- PostgreSQL 14+ / Oracle Database 19c+
