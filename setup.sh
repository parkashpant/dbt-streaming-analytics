#!/bin/bash

START_TIME=$(date +%s)
START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "Starting Streaming Analytics dbt setup...\n"
echo -e "Start time: $START_TIMESTAMP\n"

# Create and activate virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Verify activation
EXPECTED_VENV="$(pwd)/venv"
if [ "$VIRTUAL_ENV" != "$EXPECTED_VENV" ]; then
    echo -e "Error: Virtual environment is not activated for this project\n"
    echo -e "Expected: $EXPECTED_VENV\n"
    echo -e "Current:  ${VIRTUAL_ENV:-"none"}\n"
    exit 1
fi

echo -e "Virtual environment activated: $VIRTUAL_ENV\n"

# Install dependencies
pip3.11 install -r requirements.txt

# Start PostgreSQL via Docker
docker-compose up -d

echo -e "Waiting for database...\n"
sleep 8

# Wait until PostgreSQL is ready
echo -e "Checking database connection...\n"
until docker exec streaming_postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo -e "Still waiting for PostgreSQL...\n"
    sleep 2
done

echo -e "Database is ready!\n"

# Navigate to dbt project
cd dbt-streaming

echo -e "Installing dbt packages...\n"
dbt deps --profiles-dir .dbt --target dev

echo -e "Loading seed data into PostgreSQL...\n"
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
