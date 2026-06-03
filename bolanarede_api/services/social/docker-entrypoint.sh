#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/social/scripts/migrate.js

echo "Starting social service..."
exec node /app/services/social/dist/services/social/src/main
