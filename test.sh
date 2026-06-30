#!/usr/bin/env bash
#
# test.sh - End-to-end idempotency test for all db/ SQL scripts.
#
# What it does:
#   1. Starts a fresh MSSQL Server container with an ephemeral volume.
#   2. Waits for the server to become ready.
#   3. Executes every .sql file under ./db in alphabetical/numeric order,
#      twice each, and validates idempotency.
#   4. Cleans up containers and volumes on exit.
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
CONTAINER_NAME="mssql-test-$(date +%s)"
VOLUME_NAME="mssql-data-test-$(date +%s)"
IMAGE="mcr.microsoft.com/mssql/server:2022-latest"
SA_PASSWORD='local-dev-pass!2026'

HOST_SCRIPTS_DIR="$(cd "$(dirname "$0")/db" && pwd)"
CONTAINER_SCRIPTS_DIR="/sql-scripts"
HOST_DATASETS_DIR="$(cd "$(dirname "$0")/datasets" && pwd)"
PORT=1433

# ---------------------------------------------------------------------------
# Cleanup trap
# ---------------------------------------------------------------------------
cleanup() {
    echo ""
    echo "=== Cleaning up ==="
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm   "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker volume rm "$VOLUME_NAME" >/dev/null 2>&1 || true
    echo "Done."
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Helper: run a sqlcmd batch inside the container.
#   Returns 0 on success, non-zero on any T-SQL error.
#   SET QUOTED_IDENTIFIER ON is prepended so indexed views / computed columns
#   work correctly (sqlcmd default is OFF).
# ---------------------------------------------------------------------------
run_sql() {
    local sql="$1"
    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U SA \
        -P "$SA_PASSWORD" \
        -C -N -b \
        -Q "SET QUOTED_IDENTIFIER ON; $sql" 2>&1
}

run_sql_file() {
    local container_path="$1"
    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U SA \
        -P "$SA_PASSWORD" \
        -C -N -b \
        -r 1 \
        -I \
        -i "$container_path" 2>&1
}

# ---------------------------------------------------------------------------
# 1. Start a fresh container with scripts and datasets bind-mounted
# ---------------------------------------------------------------------------
echo "=== Step 1: Starting fresh MSSQL container ==="
docker volume create "$VOLUME_NAME" >/dev/null
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "127.0.0.1:${PORT}:1433" \
    -e ACCEPT_EULA=Y \
    -e MSSQL_PID=Express \
    -e "MSSQL_SA_PASSWORD=${SA_PASSWORD}" \
    -v "${VOLUME_NAME}:/var/opt/mssql" \
    -v "${HOST_SCRIPTS_DIR}:${CONTAINER_SCRIPTS_DIR}:ro" \
    -v "${HOST_DATASETS_DIR}:/datasets:ro" \
    -m 4g \
    "$IMAGE" >/dev/null

echo "Container started: $CONTAINER_NAME"
echo "Volume:            $VOLUME_NAME"
echo "Scripts mounted at: $CONTAINER_SCRIPTS_DIR"
echo "Datasets mounted at: /datasets"

# ---------------------------------------------------------------------------
# 2. Wait for SQL Server to become ready
# ---------------------------------------------------------------------------
echo ""
echo "=== Step 2: Waiting for SQL Server to be ready ==="
for i in $(seq 1 60); do
    if run_sql "SELECT 1" >/dev/null 2>&1; then
        echo "SQL Server is ready (${i}s)."
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "ERROR: SQL Server did not become ready in 60 seconds."
        exit 1
    fi
    sleep 2
done

# ---------------------------------------------------------------------------
# 3. Collect SQL files (version-sort = numeric order due to zero-padding)
# ---------------------------------------------------------------------------
mapfile -t SQL_FILES < <(ls -1 "$HOST_SCRIPTS_DIR"/*.sql 2>/dev/null | sort -V)

if [ "${#SQL_FILES[@]}" -eq 0 ]; then
    echo "ERROR: No .sql files found in $HOST_SCRIPTS_DIR"
    exit 1
fi

echo ""
echo "=== Step 4: Running ${#SQL_FILES[@]} scripts (2 passes each) ==="
echo "Directory: $HOST_SCRIPTS_DIR"
echo "---"

FAIL=0
PASS_COUNT=0
TOTAL=$(( ${#SQL_FILES[@]} * 2 ))

for host_file in "${SQL_FILES[@]}"; do
    filename="$(basename "$host_file")"
    container_file="${CONTAINER_SCRIPTS_DIR}/${filename}"

    for pass in 1 2; do
        label="[Pass $pass] $filename"
        printf "  %-50s" "$label"

        # -b: quit on error (non-zero exit code)
        # -I: enable quoted identifiers (fixes indexed view creation in script 130)
        output=$(run_sql_file "$container_file" 2>&1) && rc=0 || rc=$?

        if [ $rc -ne 0 ]; then
            echo " FAILED (exit code $rc)"
            echo "  --- Output ---"
            echo "$output" | tail -20
            echo "  --------------"
            FAIL=$((FAIL + 1))
        else
            echo " OK"
            PASS_COUNT=$((PASS_COUNT + 1))
        fi
    done
done

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Results ==="
echo "Scripts tested : ${#SQL_FILES[@]}"
echo "Total runs     : $TOTAL"
echo "Passed         : $PASS_COUNT"
echo "Failed         : $FAIL"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "RESULT: SOME SCRIPTS FAILED — idempotency check did NOT pass."
    exit 1
fi

echo ""
echo "RESULT: ALL SCRIPTS PASSED BOTH RUNS — idempotency verified."
exit 0
