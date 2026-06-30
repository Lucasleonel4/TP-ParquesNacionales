#!/usr/bin/env bash
# init-db.sh — Runs all SQL scripts inside the running sqlserver container.
# Usage: docker compose up -d sqlserver && bash init-db.sh

set -e

CONTAINER="parques-sqlserver"
DB_DIR="./db"

SA_PASSWORD="${DB_PASSWORD:-StrongP@ssw0rd}"

# Wait for SQL Server to be ready
echo "Waiting for SQL Server to be ready..."
until docker exec "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd -C -U sa -P "$SA_PASSWORD" -Q 'SELECT 1' > /dev/null 2>&1; do
  sleep 3
done
echo "SQL Server is ready."

# Build sorted list of script filenames into a temp file
TMPFILE=$(mktemp)
ls -1 "$DB_DIR"/*.sql | sort -V > "$TMPFILE"

# Phase 1: Copy all SQL files into the container
while IFS= read -r script; do
  fname=$(basename "$script")
  echo "[COPY] $fname ..."
  docker cp "$script" "$CONTAINER:/tmp/$fname"
done < "$TMPFILE"

# Phase 2: Execute each script
while IFS= read -r script; do
  fname=$(basename "$script")
  echo "[RUN] $fname ..."

  if [[ "$fname" == *"010"* ]]; then
    docker exec "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
      -C -U sa -P "$SA_PASSWORD" \
      -d master \
      -i "/tmp/$fname" || { echo "[FAIL] $fname"; exit 1; }
  else
    docker exec "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
      -C -U sa -P "$SA_PASSWORD" \
      -d com2900 \
      -i "/tmp/$fname" || { echo "[FAIL] $fname"; exit 1; }
  fi
done < "$TMPFILE"

rm -f "$TMPFILE"

echo ""
echo "All scripts executed successfully."
