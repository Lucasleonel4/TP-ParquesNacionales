#!/usr/bin/env bash
#
# run.sh - Execute all db/ SQL scripts in order against the sqlserver container.
#
set -euo pipefail

SA_PASSWORD="${DB_PASSWORD:-StrongP@ssw0rd}"
CONTAINER_NAME="parques-sqlserver"

# ---------------------------------------------------------------------------
# Helper: run a SQL file inside the container.
#   $1 = database name, $2 = path to .sql file (inside container)
# ---------------------------------------------------------------------------
run_sql_file() {
    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U SA \
        -P "$SA_PASSWORD" \
        -C -N -b \
        -r 1 \
        -I \
        -d "$1" \
        -i "$2" 2>&1
}

# ---------------------------------------------------------------------------
# 3. Collect and run scripts in numeric order
# ---------------------------------------------------------------------------
mapfile -t SQL_FILES < <(ls -1 ./db/*.sql 2>/dev/null | sort -V)

if [ "${#SQL_FILES[@]}" -eq 0 ]; then
    echo "ERROR: No .sql files found in ./db"
    exit 1
fi

echo ""
echo "=== Running ${#SQL_FILES[@]} scripts ==="
echo "---"

FAIL=0
PASS_COUNT=0

for host_file in "${SQL_FILES[@]}"; do
    filename="$(basename "$host_file")"
    printf "  %-50s" "$filename"

    # Script 010 creates the database and runs against master; all others use com2900.
    if [[ "$filename" == *"010"* ]]; then
        output=$(run_sql_file "master" "/sql-scripts/$filename") && rc=0 || rc=$?
    else
        output=$(run_sql_file "com2900" "/sql-scripts/$filename") && rc=0 || rc=$?
    fi

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

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Results ==="
echo "Total runs : ${#SQL_FILES[@]}"
echo "Passed     : $PASS_COUNT"
echo "Failed     : $FAIL"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "RESULT: SOME SCRIPTS FAILED."
    exit 1
fi

echo ""
echo "RESULT: ALL SCRIPTS PASSED."
exit 0