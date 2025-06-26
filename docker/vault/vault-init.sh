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
    minio_endpoint="$MINIO_ENDPOINT" \
    root_user="$MINIO_ROOT_USER" \
    root_password="$MINIO_ROOT_PASSWORD"

vault kv put secret/data-platform/hms \
    db_user="$HMS_DB_USER" \
    db_password="$HMS_DB_PASSWORD" \
    metastore_db="$HMS_DB_NAME" \
    hms_uri="$HMS_URI"

vault kv put secret/data-platform/spark \
    spark_sql_warehouse_dir="$SPARK_SQL_WAREHOUSE_DIR" \
    hms_uri="$HMS_URI"

    # SPARK_SQL_WAREHOUSE_DIR=s3a://raw-data/warehouse
    # HMS_URI=thrift://hive-metastore:9083

vault kv put secret/data-platform/ranger \
    db_user="$RANGER_DB_USER" \
    db_password="$RANGER_DB_PASSWORD"

vault kv put secret/data-platform/airflow \
    sql_alchemy_uri="$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"

echo "✅ Vault secrets successfully written."