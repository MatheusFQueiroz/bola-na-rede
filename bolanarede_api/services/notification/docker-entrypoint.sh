#!/bin/sh
set -e
echo "Setting up MongoDB indexes..."
node /app/services/notification/scripts/setup-indexes.js
echo "Starting notification service..."
exec node /app/services/notification/dist/services/notification/src/main
