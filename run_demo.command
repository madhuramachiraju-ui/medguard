#!/bin/bash
# Double-click this file. It opens Terminal and runs the full MedGuard QA demo.
cd "$(dirname "$0")"
clear
echo "=== MedGuard QA: starting Docker containers ==="
docker compose up -d --build || { echo "Something failed (is Docker Desktop open? is a port already in use?). Scroll up for the error."; read -p "Press Enter to close"; exit 1; }
echo
docker compose build tests
echo "=== Running Selenium tests (watch the browser at http://localhost:7900, password: secret) ==="
set -a; [ -f .env ] && . ./.env; set +a
docker compose run --rm tests
echo
open reports/traceability.html
read -p "Done. Press Enter to close"
