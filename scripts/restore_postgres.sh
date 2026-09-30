#!/bin/bash
# Ferrox Ecosystem - PostgreSQL Restore Utility
# Usage: ./restore_postgres.sh <container_name> <db_name> <db_user> <backup_file.sql.gz>

CONTAINER_NAME=${1:-ferrox-postgres}
DB_NAME=${2:-ferrox}
DB_USER=${3:-ferrox}
BACKUP_FILE=$4

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file not specified."
    echo "Usage: ./restore_postgres.sh <container_name> <db_name> <db_user> <backup_file.sql.gz>"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file '$BACKUP_FILE' not found."
    exit 1
fi

echo "⚠️ WARNING: This will overwrite the current database '$DB_NAME'."
read -p "Are you sure you want to proceed? (y/N): " confirm
if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
    echo "Restore aborted."
    exit 0
fi

echo "Restoring database '$DB_NAME' from '$BACKUP_FILE'..."

# Unzip on the fly and restore via psql
gunzip -c "$BACKUP_FILE" | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME

if [ $? -eq 0 ]; then
    echo "✅ Restore completed successfully."
else
    echo "❌ Restore failed! Check the backup file integrity and container status."
    exit 1
fi
