#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/field/scripts/migrate.js

echo "Starting field service..."
exec node /app/services/field/dist/services/field/src/main
