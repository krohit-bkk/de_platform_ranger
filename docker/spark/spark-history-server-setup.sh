#!/bin/bash
set -e

# Blue info log
function info() {
  echo -e "\n\e[1;34m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

info "Starting Spark History Server setup..."

# The bitnami/spark image is debian-based. We need to install necessary packages.
info "Installing dependencies: curl, jq, gettext-base..."
apt-get update && apt-get install -y curl jq gettext-base && apt-get clean

# --- Vault Integration ---
export VAULT_ADDR=${VAULT_ADDR:-http://vault:8200}
VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID:-root}

fetch_from_vault() {
  local key="$1"
  local secret_path="$2"
  curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/secret/data/${secret_path}" \
    | jq -r ".data.data[\"${key}\"]"
}

info "Waiting for Vault to be ready at ${VAULT_ADDR}..."
until curl -s -f "${VAULT_ADDR}/v1/sys/health" > /dev/null; do
    echo "Vault is unavailable - sleeping"
    sleep 5
done
info "✅ Vault is ready!"

info "🔐 Fetching MinIO credentials from Vault..."
export MINIO_ENDPOINT=$(fetch_from_vault "minio_endpoint" "data-platform/minio")
export MINIO_ROOT_USER=$(fetch_from_vault "minio_root_user" "data-platform/minio")
export MINIO_ROOT_PASSWORD=$(fetch_from_vault "minio_root_password" "data-platform/minio")
info "✅ Successfully retrieved MinIO credentials from Vault."

info "🧪 Rendering spark-defaults.conf from template..."
envsubst < /opt/bitnami/spark/conf/spark-defaults.conf.tmpl > /opt/bitnami/spark/conf/spark-defaults.conf

info "Configuration generated successfully. Contents:"
cat /opt/bitnami/spark/conf/spark-defaults.conf

info "Starting Spark History Server..."
# Use exec to replace the shell process with the history server process
exec /opt/bitnami/spark/sbin/start-history-server.sh