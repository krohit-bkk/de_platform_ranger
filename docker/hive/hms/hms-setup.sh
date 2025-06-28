#!/bin/bash

set -e
# Prints messages in blue color for better visibility
function info() {
  echo -e "\n\e[1;34m$1\e[0m\n"
} 

curr_user=$(whoami)
info "\n>>>> User in action (inside setup-server.sh): $curr_user\n"

# install necessary packages for fetching secrets from Vault
apt-get update && apt-get install -y curl jq gettext wget netcat postgresql-client gosu && apt-get clean


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
info "🔐 Fetching MinIO credentials from Vault..."
export MINIO_ROOT_USER=$(fetch_from_vault "minio_root_user" "data-platform/minio")
export MINIO_ROOT_PASSWORD=$(fetch_from_vault "minio_root_password" "data-platform/minio")

# Get postgreSQL secrets from Vault
info "🔐 Fetching PostgreSQL credentials from Vault..."
export POSTGRES_USER=$(fetch_from_vault "hms_db_user" "data-platform/hms")
export POSTGRES_PASSWORD=$(fetch_from_vault "hms_db_password" "data-platform/hms")
export POSTGRES_DB=$(fetch_from_vault "hms_db_name" "data-platform/hms")

export DB_DRIVER=postgres
export DB_CONNECTION_URL=jdbc:postgresql://postgres:5432/${POSTGRES_DB}
export DB_USER=${POSTGRES_USER}
export DB_PASSWORD=${POSTGRES_PASSWORD}
export HIVE_SKIP_HADOOP_VERSION_CHECK="true" # Add this to bypass HDFS checks
export IS_RESUME="true"

# Verify environment variables
info ">>>> POSTGRES_DB: ${POSTGRES_DB}"

# 🧪 Render hive-site.xml dynamically
info "🧪 Rendering hive-site.xml from template..."
envsubst < /opt/hive/conf/hive-site.xml.tmpl > /opt/hive/conf/hive-site.xml

# Downloading dependencies
# wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.375/aws-java-sdk-bundle-1.11.375.jar
# wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar
# wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/org/postgresql/postgresql/42.3.1/postgresql-42.3.1.jar

# Defining dependencies
declare -A jars=(
  ["aws-java-sdk-bundle-1.11.375.jar"]="https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.375/aws-java-sdk-bundle-1.11.375.jar"
  ["hadoop-aws-3.2.0.jar"]="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar"
  ["postgresql-42.3.1.jar"]="https://repo1.maven.org/maven2/org/postgresql/postgresql/42.3.1/postgresql-42.3.1.jar"
)

# Target directory
TARGET_DIR="/opt/hive/lib"

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Download only if not already present
for jar in "${!jars[@]}"; do
  if [[ ! -f "$TARGET_DIR/$jar" ]]; then
    info "⬇️  Downloading $jar..."
    wget -q -P "$TARGET_DIR" "${jars[$jar]}"
  else
    info "✅ $jar already exists. Skipping download."
  fi
done

info ">>>> wget done"
install -d -m 777 /tmp/hive 

# gosu hive and continue
gosu hive /opt/hive/init-schema.sh 2>&1
