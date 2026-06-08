#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/ranking/scripts/migrate.js

echo "Starting ranking service..."
exec node /app/services/ranking/dist/services/ranking/src/main
