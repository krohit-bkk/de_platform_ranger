#!/bin/sh
set -e

# Prints messages in blue color for better visibility
function info() {
  echo -e "\n\e[1;34m$1\e[0m\n"
} 

info "⏳ Waiting for Vault to be ready..."
sleep 5

export VAULT_ADDR=http://vault:8200
export VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID}

info "📄 Sourcing evaluated env vars..."
set -a
source /secrets/.env.evaluated
set +a

info "🔐 Writing secrets to Vault..."

vault kv put secret/data-platform/minio \
    minio_endpoint="$MINIO_ENDPOINT" \
    minio_root_user="$MINIO_ROOT_USER" \
    minio_root_password="$MINIO_ROOT_PASSWORD"

vault kv put secret/data-platform/hms \
    hms_db_user="$HMS_DB_USER" \
    hms_db_password="$HMS_DB_PASSWORD" \
    hms_uri="$HMS_URI" \
    hms_pg_jdbc="$HMS_PG_JDBC" \
    hms_db_name="$HMS_DB_NAME"

vault kv put secret/data-platform/spark \
    spark_sql_warehouse_dir="$SPARK_SQL_WAREHOUSE_DIR" \
    hms_uri="$HMS_URI"

vault kv put secret/data-platform/ranger \
    db_user="$RANGER_DB_USER" \
    db_password="$RANGER_DB_PASSWORD"

vault kv put secret/data-platform/airflow \
    sql_alchemy_uri="$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"

info "✅ Vault secrets successfully written."