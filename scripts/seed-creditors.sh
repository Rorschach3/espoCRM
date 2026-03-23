#!/usr/bin/env bash
# Seed common creditors and collection agencies
set -euo pipefail

BASE_URL="${SITE_URL:-http://localhost:8080}"
ADMIN_USER="${ADMIN_USERNAME:-admin}"
ADMIN_PASS="${ADMIN_PASSWORD:-password}"
API="${BASE_URL}/api/v1"

post_creditor() {
  local name="$1"
  local type="$2"
  local result
  result=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -u "${ADMIN_USER}:${ADMIN_PASS}" \
    -d "{\"name\": \"${name}\", \"creditorType\": \"${type}\"}" \
    "${API}/Creditor")
  echo "    Created: ${name}"
}

echo "==> Seeding credit bureaus..."
post_creditor "Equifax" "Original Creditor"
post_creditor "Experian" "Original Creditor"
post_creditor "TransUnion" "Original Creditor"

echo "==> Seeding collection agencies..."
post_creditor "Midland Credit Management" "Collection Agency"
post_creditor "Portfolio Recovery Associates" "Collection Agency"
post_creditor "Convergent Outsourcing" "Collection Agency"
post_creditor "Encore Capital Group" "Collection Agency"
post_creditor "LVNV Funding" "Collection Agency"
post_creditor "Cavalry Portfolio Services" "Collection Agency"
post_creditor "Asset Acceptance LLC" "Collection Agency"

echo "==> Seeding common creditors..."
post_creditor "Capital One" "Credit Card"
post_creditor "Discover Financial" "Credit Card"
post_creditor "Synchrony Bank" "Credit Card"
post_creditor "Comenity Bank" "Credit Card"
post_creditor "Bank of America" "Credit Card"
post_creditor "Chase" "Credit Card"
post_creditor "Wells Fargo" "Credit Card"
post_creditor "Citibank" "Credit Card"

echo "==> Creditor seeding complete."
