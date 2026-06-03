#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/open-game/scripts/migrate.js

echo "Starting open-game service..."
exec node /app/services/open-game/dist/services/open-game/src/main
