#!/bin/sh
set -e

echo "🔐 Fetching MinIO credentials from Vault..."

# Wait for Vault to be ready
until echo "$(curl -s http://vault:8200/v1/sys/health)" | \
  case $(cat) in *'"initialized":true,"sealed":false'*) true;; *) false;; esac
do
  echo "Waiting for Vault to be ready..."
  sleep 2
done


export VAULT_ADDR=http://vault:8200
VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID:-root}

# Get creds from Vault
fetch_from_vault() {
  local key="$1"
  local secret_path="$2"

  curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/secret/data/${secret_path}" \
    | jq -r ".data.data[\"${key}\"]"
}

echo "🔐 Fetching MinIO credentials from Vault..."
export MINIO_ROOT_USER=$(fetch_from_vault "root_user" "data-platform/minio")
export MINIO_ROOT_PASSWORD=$(fetch_from_vault "root_password" "data-platform/minio")

echo "✅ Got MinIO creds from Vault\n"

# Start MinIO server in background
minio server /data --console-address :9001 &

# Wait a bit for MinIO to boot
sleep 10

# Create buckets
echo "Going to create buckets..."
/create-buckets.sh

# Keep container running
tail -f /dev/null
