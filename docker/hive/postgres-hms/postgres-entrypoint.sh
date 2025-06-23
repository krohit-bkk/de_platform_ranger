#!/bin/bash
set -e

# Install curl for fetching secrets from Vault
apt-get update && apt-get install -y curl jq && apt-get clean

echo "🔐 Fetching PostgreSQL secrets from Vault..."

# Default values (if not set by environment)
VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
VAULT_SECRET_PATH="secret/data/data-platform/hms"

# # Helper function to fetch a specific secret key
fetch_from_vault() {
  local key="$1"
  local secret_path="$2"

  curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/secret/data/${secret_path}" \
    | jq -r ".data.data[\"${key}\"]"
}

echo "🔐 Fetching MinIO credentials from Vault..."
export POSTGRES_USER=$(fetch_from_vault "db_user" "data-platform/hms")
export POSTGRES_PASSWORD=$(fetch_from_vault "db_password" "data-platform/hms")
export POSTGRES_DB=$(fetch_from_vault "metastore_db" "data-platform/hms")

echo "✅ Secrets loaded: POSTGRES_USER=$POSTGRES_USER, DB=$POSTGRES_DB"

# Start PostgreSQL using the default entrypoint
exec docker-entrypoint.sh postgres
