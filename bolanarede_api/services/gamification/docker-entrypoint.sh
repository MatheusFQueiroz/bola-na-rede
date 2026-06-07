#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/gamification/scripts/migrate.js

echo "Starting gamification service..."
exec node /app/services/gamification/dist/services/gamification/src/main
