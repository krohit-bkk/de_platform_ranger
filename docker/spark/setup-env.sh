# Set up Spark environment variables
# ==================================
echo -e "Setting up Spark environment... \n"
install_packages curl jq gettext netcat

# Fetch secrets from Vault
# ========================
# Get secrets from Vault
export VAULT_ADDR=http://vault:8200
VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID:-root}
fetch_from_vault() {
  local key="$1"
  local secret_path="$2"

  curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/secret/data/${secret_path}" \
    | jq -r ".data.data[\"${key}\"]"
}

# Get MinIO secrets from Vault
echo -e "\n🔐 Fetching MinIO credentials from Vault..."
export MINIO_ENDPOINT=$(fetch_from_vault "minio_endpoint" "data-platform/minio")
export MINIO_ROOT_USER=$(fetch_from_vault "root_user" "data-platform/minio")
export MINIO_ROOT_PASSWORD=$(fetch_from_vault "root_password" "data-platform/minio")

# Get Hive Metastore secrets from Vault
echo -e "\n🔐 Fetching Hive Metastore credentials from Vault... "
export HMS_URI=$(fetch_from_vault "hms_uri" "data-platform/hms")

# Get Spark secrets from Vault
export SPARK_SQL_WAREHOUSE_DIR=$(fetch_from_vault "spark_sql_warehouse_dir" "data-platform/spark")
export HMS_URI=$(fetch_from_vault "hms_uri" "data-platform/spark")

echo -e "\nSecrets have been extracted from the Vault... \n"

