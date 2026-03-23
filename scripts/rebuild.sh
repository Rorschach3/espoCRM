#!/usr/bin/env bash
# Deploy custom module files and trigger EspoCRM rebuild
# Usage: bash scripts/rebuild.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_DIR="${SCRIPT_DIR}/../custom"

echo "==> Copying custom module files into container..."
docker cp "${CUSTOM_DIR}/Espo/Custom/Resources/." espocrm:/var/www/html/custom/Espo/Custom/Resources/
docker cp "${CUSTOM_DIR}/Espo/Custom/Controllers/." espocrm:/var/www/html/custom/Espo/Custom/Controllers/

echo "==> Clearing cache..."
docker exec espocrm bash -c 'rm -rf /var/www/html/data/cache/*'

echo "==> Rebuilding EspoCRM (metadata + schema)..."
docker exec espocrm php command.php rebuild

echo "==> Done. Custom entities are active."
