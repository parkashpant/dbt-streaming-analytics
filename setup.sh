#!/bin/bash
set -e

START_TIME=$(date +%s)
START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "Starting Streaming Analytics dbt setup...\n"
echo -e "Start time: $START_TIMESTAMP\n"

# Ensure uv is installed
if ! command -v uv > /dev/null 2>&1; then
    echo -e "Error: uv is not installed. Install it with:\n"
    echo -e "  curl -LsSf https://astral.sh/uv/install.sh | sh\n"
    exit 1
fi

# Install dbt v2 as a standalone CLI (DuckDB adapter is built in)
export PATH="$HOME/.local/bin:$PATH"
if ! dbt --version 2>/dev/null | grep -q "dbt 2\."; then
    echo -e "Installing dbt v2...\n"
    uv tool install --force dbt
fi

echo -e "Using $(dbt --version | head -1)\n"

# Navigate to dbt project
cd dbt-streaming

echo -e "Installing dbt packages...\n"
dbt deps --profiles-dir .dbt --target dev

echo -e "Loading seed data into DuckDB (warehouse.duckdb)...\n"
dbt seed --profiles-dir .dbt --target dev

echo -e "Building dbt models...\n"
dbt build --profiles-dir .dbt --target dev

echo -e "Querying analyses...\n"
dbt show --select artist_performance  --profiles-dir .dbt --target dev --limit 5
dbt show --select label_performance  --profiles-dir .dbt --target dev --limit 5
dbt show --select track_performance  --profiles-dir .dbt --target dev --limit 5

END_TIME=$(date +%s)
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo -e "\nSetup completed successfully!"
echo -e "End time: $END_TIMESTAMP"
echo -e "Total duration: ${MINUTES}m ${SECONDS}s"
