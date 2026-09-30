#!/bin/bash
# Ferrox Ecosystem - PostgreSQL Backup Utility
# Usage: ./backup_postgres.sh <container_name> <db_name> <db_user> <output_dir>

CONTAINER_NAME=${1:-ferrox-postgres}
DB_NAME=${2:-ferrox}
DB_USER=${3:-ferrox}
OUTPUT_DIR=${4:-./backups}

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$OUTPUT_DIR/ferrox_pg_${TIMESTAMP}.sql.gz"

echo "Initiating backup of Database '$DB_NAME' from container '$CONTAINER_NAME'..."

# Execute pg_dump inside the container and compress it on the fly
docker exec -t $CONTAINER_NAME pg_dump -U $DB_USER -d $DB_NAME -F p | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup successfully created at: $BACKUP_FILE"
else
    echo "❌ Backup failed! Please check container status."
    exit 1
fi
