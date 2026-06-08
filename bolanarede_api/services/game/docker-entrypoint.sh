#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/game/scripts/migrate.js

echo "Starting game service..."
exec node /app/services/game/dist/services/game/src/main
