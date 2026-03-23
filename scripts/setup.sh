#!/usr/bin/env bash
# Credit Repair CRM — EspoCRM post-start setup
# Run after containers are healthy: bash scripts/setup.sh
set -euo pipefail

BASE_URL="${SITE_URL:-http://localhost:8080}"
ADMIN_USER="${ADMIN_USERNAME:-admin}"
ADMIN_PASS="${ADMIN_PASSWORD:-password}"
API="${BASE_URL}/api/v1"

echo "==> Waiting for EspoCRM to be ready..."
until curl -sf -o /dev/null -w "%{http_code}" "${BASE_URL}" | grep -qE "^(200|302)"; do
  echo "    ...not ready yet, retrying in 5s"
  sleep 5
done
echo "    EspoCRM is reachable."

echo "==> Verifying admin credentials..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${API}/App/user" -u "${ADMIN_USER}:${ADMIN_PASS}")
if [ "${HTTP_CODE}" != "200" ]; then
  echo "ERROR: Admin login failed (HTTP ${HTTP_CODE})."
  echo "       Check ADMIN_USER and ADMIN_PASS in your .env file."
  echo "       Running instance password is the one set at container creation time."
  exit 1
fi
echo "    Credentials OK."

# Helper: POST to EspoCRM API
post() {
  local endpoint="$1"
  local data="$2"
  curl -sf -X POST \
    -H "Content-Type: application/json" \
    -u "${ADMIN_USER}:${ADMIN_PASS}" \
    -d "${data}" \
    "${API}/${endpoint}"
}

# Helper: PUT to EspoCRM API
put() {
  local endpoint="$1"
  local data="$2"
  curl -sf -X PUT \
    -H "Content-Type: application/json" \
    -u "${ADMIN_USER}:${ADMIN_PASS}" \
    -d "${data}" \
    "${API}/${endpoint}"
}

echo ""
echo "==> Rebuilding metadata cache..."
curl -sf -X POST \
  -u "${ADMIN_USER}:${ADMIN_PASS}" \
  "${API}/Admin/rebuildMetadata" || true

echo ""
echo "==> Clearing cache..."
curl -sf -X POST \
  -u "${ADMIN_USER}:${ADMIN_PASS}" \
  "${API}/Admin/clearCache" || true

echo ""
echo "==> Running schema diff (creating custom tables)..."
curl -sf -X POST \
  -u "${ADMIN_USER}:${ADMIN_PASS}" \
  "${API}/Admin/runRebuild" || true

echo ""
echo "==> Creating Credit Repair Specialist role..."
ROLE_RESPONSE=$(post "Role" '{
  "name": "Credit Repair Specialist",
  "data": {
    "CreditClient": {"read": "all", "edit": "team", "delete": "no", "create": "yes", "stream": "all"},
    "DisputeItem": {"read": "all", "edit": "team", "delete": "no", "create": "yes", "stream": "all"},
    "DisputeRound": {"read": "all", "edit": "team", "delete": "no", "create": "yes", "stream": "all"},
    "DisputeLetter": {"read": "all", "edit": "team", "delete": "no", "create": "yes", "stream": "all"},
    "CreditReport": {"read": "all", "edit": "team", "delete": "no", "create": "yes", "stream": "no"},
    "Creditor": {"read": "all", "edit": "team", "delete": "no", "create": "yes"},
    "PaymentPlan": {"read": "team", "edit": "no", "delete": "no", "create": "no"}
  }
}') || true
echo "    Role response: ${ROLE_RESPONSE}"

echo ""
echo "==> Creating Billing Manager role..."
BILLING_ROLE=$(post "Role" '{
  "name": "Billing Manager",
  "data": {
    "CreditClient": {"read": "all", "edit": "no", "delete": "no", "create": "no"},
    "PaymentPlan": {"read": "all", "edit": "all", "delete": "team", "create": "yes"},
    "DisputeItem": {"read": "all", "edit": "no", "delete": "no", "create": "no"},
    "DisputeRound": {"read": "all", "edit": "no", "delete": "no", "create": "no"},
    "DisputeLetter": {"read": "all", "edit": "no", "delete": "no", "create": "no"},
    "CreditReport": {"read": "all", "edit": "no", "delete": "no", "create": "no"},
    "Creditor": {"read": "all", "edit": "no", "delete": "no", "create": "no"}
  }
}') || true
echo "    Billing role response: ${BILLING_ROLE}"

echo ""
echo "==> Seeding default creditors..."
bash "$(dirname "$0")/seed-creditors.sh" 2>/dev/null || true

echo ""
echo "==> Done! Log in at ${BASE_URL}"
echo "    Admin: ${ADMIN_USER} / ${ADMIN_PASS}"
echo ""
echo "    IMPORTANT: After first login, go to:"
echo "    Administration > Rebuild to apply schema changes."
