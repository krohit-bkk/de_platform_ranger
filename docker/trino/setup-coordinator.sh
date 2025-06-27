#!/bin/bash
set -e

echo "🔧 [Trino] Setting up Coordinator..."

# Step 1: Install dependencies if not already installed
echo "📦 Checking and installing dependencies..."
for pkg in curl jq netcat gettext; do
  if ! command -v $pkg &> /dev/null; then
    echo ">>>> Installing $pkg..."
    apt-get update && apt-get install -y $pkg
  fi
done

# Step 2: Fetch secrets from Vault
echo "🔐 Fetching secrets from Vault..."
export VAULT_ADDR=http://vault:8200
VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID:-root}

fetch_from_vault() {
  local key="$1"
  local secret_path="$2"
  curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/secret/data/${secret_path}" \
    | jq -r ".data.data[\"${key}\"]"
}

# Export required values from Vault
export HMS_URI=$(fetch_from_vault "hms_uri" "data-platform/hms")
export HMS_PG_JDBC=$(fetch_from_vault "hms_pg_jdbc" "data-platform/hms")
export HMS_DB_NAME=$(fetch_from_vault "hms_db_name" "data-platform/hms")
export HMS_DB_USER=$(fetch_from_vault "db_user" "data-platform/hms")
export HMS_DB_PASSWORD=$(fetch_from_vault "db_password" "data-platform/hms")

export MINIO_ENDPOINT=$(fetch_from_vault "minio_endpoint" "data-platform/minio")
export MINIO_ROOT_USER=$(fetch_from_vault "root_user" "data-platform/minio")
export MINIO_ROOT_PASSWORD=$(fetch_from_vault "root_password" "data-platform/minio")

# Verify environment variables
echo -e "\nHMS_URI: ${HMS_URI}\n"

# Step 3: Generate final catalog configs
echo "📄 Generating catalog configs from templates..."
envsubst < /etc/trino/catalog/hive.properties.tmpl > /etc/trino/catalog/hive.properties
envsubst < /etc/trino/catalog/delta.properties.tmpl > /etc/trino/catalog/delta.properties

# Step 4: Start Trino Coordinator
rm -rf /usr/lib/trino/etc
ln -s /etc/trino /usr/lib/trino/etc

export TRINO_ETC_DIR=/etc/trino
echo -e "\n>>>> TRINO_ETC_DIR: ${TRINO_ETC_DIR}\n"

echo "🚀 Starting Trino Coordinator..."
exec /usr/lib/trino/bin/launcher run