#!/bin/bash

set -e
# Blue info log
function info() {
  echo -e "\n\e[1;34m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

# Yellow warning log
function warn() {
  echo -e "\n\e[1;33m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

# Red fatal log
function fatal() {
  echo -e "\n\e[1;31m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

info "🔧 [Trino] Setting up Coordinator..."

# Step 1: Install dependencies if not already installed
info "📦 Checking and installing dependencies..."
for pkg in curl jq netcat gettext uuid-runtime; do
  if ! command -v $pkg &> /dev/null; then
    info ">>>> Installing $pkg..."
    apt-get update && apt-get install -y $pkg
  fi
done

# Step 2: Fetch secrets from Vault
info "🔐 Fetching secrets from Vault..."
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
export HMS_DB_USER=$(fetch_from_vault "hms_db_user" "data-platform/hms")
export HMS_DB_PASSWORD=$(fetch_from_vault "hms_db_password" "data-platform/hms")

export MINIO_ENDPOINT=$(fetch_from_vault "minio_endpoint" "data-platform/minio")
export MINIO_ROOT_USER=$(fetch_from_vault "minio_root_user" "data-platform/minio")
export MINIO_ROOT_PASSWORD=$(fetch_from_vault "minio_root_password" "data-platform/minio")

# Step 3: Coordinator-specific config
export TRINO_IS_COORDINATOR=true
export TRINO_INCLUDE_COORDINATOR=true
export TRINO_DISCOVERY_ENABLED=true

# Step 4: Generate config.properties from template
info "🛠️ Generating config.properties..."
envsubst < /etc/trino/config.properties.tmpl > /etc/trino/config.properties

# Step 5: Generate node.properties fresh
NODE_ID=$(uuidgen | tr -d '-' | cut -c1-20)
cat > /etc/trino/node.properties <<EOF
node.environment=production
node.id=${NODE_ID}
node.data-dir=/data/trino
EOF
info "✅ node.properties created with node.id=${NODE_ID}"

# Step 6: Generate catalogs
info "📄 Generating Hive and Delta catalogs..."
envsubst < /etc/trino/catalog/hive.properties.tmpl > /etc/trino/catalog/hive.properties
envsubst < /etc/trino/catalog/delta.properties.tmpl > /etc/trino/catalog/delta.properties

# Step 7: Wait for Hive Metastore
info "⌛ Waiting for Hive Metastore to be ready..."
while ! nc -z hive-metastore 9083 >/dev/null; do
  info "[$(date '+%Y-%m-%d %H:%M:%S')] - Hive Metastore is not up yet! Retrying in 10 seconds..."
  sleep 10
done
info "[$(date '+%Y-%m-%d %H:%M:%S')] - Hive Metastore is UP ✅\n"

# Step 8: Symlink config dir
rm -rf /usr/lib/trino/etc
ln -s /etc/trino /usr/lib/trino/etc

# Step 9: Start Trino Coordinator
export TRINO_ETC_DIR=/etc/trino
info ">>>> TRINO_ETC_DIR: ${TRINO_ETC_DIR}"
info "🚀 Starting Trino Coordinator..."
exec /usr/lib/trino/bin/launcher run
