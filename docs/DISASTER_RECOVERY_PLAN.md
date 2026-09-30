# Ferrox Ecosystem - Disaster Recovery Plan (DRP)

## 1. Overview
This document outlines the **Disaster Recovery Plan** for the Ferrox Polyglot Ecosystem (PHP, Python, Node, Java). It ensures that critical state layers (PostgreSQL and Redis) are protected and rapidly recoverable in the event of hardware failure, data corruption, or severe cyber-attacks.

### Service Level Objectives (SLOs)
- **RPO (Recovery Point Objective):** 1 Hour (Maximum acceptable data loss).
- **RTO (Recovery Time Objective):** 15 Minutes (Maximum time to restore full service).

---

## 2. Backup Strategy

### PostgreSQL (Persistent Relational Data)
Contains users, configuration, financial ledgers, and IAM roles.
- **Method:** `pg_dump` with gzip compression via the provided `backup_postgres.sh` script.
- **Frequency:** Nightly Full Backup + Continuous WAL (Write-Ahead Log) archiving to AWS S3 / GCS.

### Redis (Ephemeral & Streaming Data)
Contains WebSockets active sessions, DAG execution state, and crypto Data Contracts queue.
- **Method:** `BGSAVE` snapshotting extracted via `backup_redis.sh`.
- **Frequency:** Every 4 hours (Since it acts mainly as an Event Sourcing queue and caching layer).

---

## 3. Disaster Scenarios & Playbooks

### Scenario A: Database Corruption or Accidental Drop
**Symptom:** API Gateway returns 500. `ferrox-php` logs report missing tables.
**Action:**
1. Block ingress traffic (Set WAF to maintenance mode).
2. Locate the latest backup in the secure vault (`./backups`).
3. Run the restore utility:
   ```bash
   ./scripts/restore_postgres.sh ferrox-postgres ferrox ferrox ./backups/ferrox_pg_LATEST.sql.gz
   ```
4. Verify data integrity via standard health checks.
5. Re-enable ingress traffic.

### Scenario B: Total Node Failure (Bare-Metal / VPS Crash)
**Symptom:** Server is completely unreachable.
**Action:**
1. Provision a new VPS via Terraform (`cd terraform/vps && terraform apply`).
2. Terraform will automatically recreate the `docker-compose.yml` and boot the empty ecosystem.
3. Transfer the latest backup files to the new VPS via SCP.
4. Run both `restore_postgres.sh` and restore the Redis `dump.rdb` into `/opt/ferrox/data/redis/`.
5. Restart the containers to load the state.
6. Update the DNS A-Record to point to the new VPS IP.

### Scenario C: Redis Memory OOM (Out Of Memory) Crash
**Symptom:** `ferrox-py` logs "Connection Refused" to Redis. Dashboard charts freeze.
**Action:**
1. The container orchestration (Docker Swarm/K8s) will attempt to auto-restart Redis.
2. If Redis fails to load corrupted `dump.rdb`, wipe `/data/dump.rdb` and restart.
3. *Note:* Redis is treated as ephemeral for streaming. The Data Platform will automatically resync the WebSocket ingestion engine (Binance stream) upon reconnection. No manual restore of Redis is required unless caching historical ETL state.

---

## 4. Automation and Cron Setup
For bare-metal and VPS deployments, automate the backup scripts by adding them to the host's `crontab`:

```bash
# PostgreSQL Backup - Every day at 02:00 AM
0 2 * * * /opt/ferrox/scripts/backup_postgres.sh ferrox-postgres ferrox ferrox /opt/ferrox/backups/pg >> /var/log/ferrox-backup.log 2>&1

# Redis Snapshot - Every 6 hours
0 */6 * * * /opt/ferrox/scripts/backup_redis.sh ferrox-redis /opt/ferrox/backups/redis >> /var/log/ferrox-backup.log 2>&1
```
