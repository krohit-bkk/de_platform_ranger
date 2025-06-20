#!/bin/sh

set -e

echo "⏳ Waiting for Vault to be ready..."
sleep 5

export VAULT_ADDR=http://vault:8200
export VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID}

echo "📄 Sourcing evaluated env vars..."
set -a
source /secrets/.env.evaluated
set +a

echo "🔐 Writing secrets to Vault..."

vault kv put secret/data-platform/minio \
    root_user="$MINIO_ROOT_USER" \
    root_password="$MINIO_ROOT_PASSWORD"

vault kv put secret/data-platform/hms \
    db_user="$HMS_DB_USER" \
    db_password="$HMS_DB_PASSWORD" \
    metastore_db="$HMS_DB_NAME"

vault kv put secret/data-platform/ranger \
    db_user="$RANGER_DB_USER" \
    db_password="$RANGER_DB_PASSWORD"

vault kv put secret/data-platform/airflow \
    sql_alchemy_uri="$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"

echo "✅ Vault secrets successfully written."