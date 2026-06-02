#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/team/scripts/migrate.js

echo "Starting team service..."
exec node /app/services/team/dist/services/team/src/main
