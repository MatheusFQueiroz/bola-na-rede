#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/identity/scripts/migrate.js

echo "Starting identity service..."
exec node /app/services/identity/dist/services/identity/src/main
