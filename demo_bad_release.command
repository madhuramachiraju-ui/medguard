#!/bin/bash
# Double-click: swaps in a faulty AI model, re-runs tests, and a Jira bug is filed automatically.
cd "$(dirname "$0")"
clear
set -a; [ -f .env ] && . ./.env; set +a
echo "=== Deploying BAD model release 1.1.0-bad ==="
GAN_BUG=1 GAN_VERSION=1.1.0-bad IMAGE_TAG=bad-release docker compose up -d --build gan app
echo
docker compose build tests
echo "=== Running tests against the bad release ==="
IMAGE_TAG=bad-release docker compose run --rm -e IMAGE_TAG=bad-release tests
open reports/traceability.html
read -p "Done. Press Enter to close"
