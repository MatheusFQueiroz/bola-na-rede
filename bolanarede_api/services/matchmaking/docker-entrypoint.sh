#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/matchmaking/scripts/migrate.js

echo "Starting matchmaking service..."
exec node /app/services/matchmaking/dist/services/matchmaking/src/main
