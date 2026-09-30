#!/bin/bash
# Ferrox Ecosystem - Redis Backup Utility (RDB Snapshot)
# Usage: ./backup_redis.sh <container_name> <output_dir>

CONTAINER_NAME=${1:-ferrox-redis}
OUTPUT_DIR=${2:-./backups}

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$OUTPUT_DIR/ferrox_redis_${TIMESTAMP}.rdb"

echo "Initiating Redis BGSAVE in container '$CONTAINER_NAME'..."
docker exec -it $CONTAINER_NAME redis-cli BGSAVE

echo "Waiting for background save to complete..."
sleep 3

# Copy the dump.rdb file from the container
echo "Extracting snapshot to $BACKUP_FILE..."
docker cp $CONTAINER_NAME:/data/dump.rdb "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Redis backup successfully saved at: $BACKUP_FILE"
else
    echo "❌ Redis backup failed!"
    exit 1
fi
