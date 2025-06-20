#!/bin/bash
set -e
cd /opt/hive/

# Crtical directories
install -d -m 777 /home/hive/.beeline
install -d -m 777 /opt/hive/logs/
touch /opt/hive/logs/stdout.log

# Installing necessary packages
echo -e "\n>>>> Installing dependencies...\n"
apt-get update && apt-get install -y curl jq gettext netcat net-tools gosu wget vim && apt-get clean

# Getting IP address of Hive Metastore because docker is appending network name in the HMS hostname
ip=$(getent hosts hive-metastore | awk '{ print $1 }')
echo "${ip} hive-metastore" >> /etc/hosts

# Downloading dependencies
wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.375/aws-java-sdk-bundle-1.11.375.jar
wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar
wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/org/postgresql/postgresql/42.3.1/postgresql-42.3.1.jar
echo -e "\n>>>> Fetching Vault secrets for PostgreSQL...\n"

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
echo "🔐 Fetching MinIO credentials from Vault..."
export MINIO_ROOT_USER=$(fetch_from_vault "root_user" "data-platform/minio")
export MINIO_ROOT_PASSWORD=$(fetch_from_vault "root_password" "data-platform/minio")

# Get postgreSQL secrets from Vault
echo "🔐 Fetching PostgreSQL credentials from Vault..."
export POSTGRES_USER=$(fetch_from_vault "db_user" "data-platform/hms")
export POSTGRES_PASSWORD=$(fetch_from_vault "db_password" "data-platform/hms")
export POSTGRES_DB=$(fetch_from_vault "metastore_db" "data-platform/hms")

export DB_DRIVER=postgres
export DB_CONNECTION_URL=jdbc:postgresql://postgres:5432/${POSTGRES_DB}
export DB_USER=${POSTGRES_USER}
export DB_PASSWORD=${POSTGRES_PASSWORD}
export HIVE_SKIP_HADOOP_VERSION_CHECK="true" # Add this to bypass HDFS checks
export IS_RESUME="true"

echo ">>>> MINIO_ROOT_USER: ${MINIO_ROOT_USER}"
echo ">>>> MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}"
echo ">>>> POSTGRES_USER: ${POSTGRES_USER}"
echo ">>>> POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}"
echo ">>>> POSTGRES_DB: ${POSTGRES_DB}"
echo ">>>> DB_DRIVER: ${DB_DRIVER}"
echo ">>>> DB_CONNECTION_URL: ${DB_CONNECTION_URL}"
echo ">>>> DB_USER: ${DB_USER}"
echo ">>>> DB_PASSWORD: ${DB_PASSWORD}"
echo ">>>> HIVE_SKIP_HADOOP_VERSION_CHECK: ${HIVE_SKIP_HADOOP_VERSION_CHECK}"
echo ">>>> IS_RESUME: ${IS_RESUME}"

# 🧪 Render hive-site.xml dynamically
echo "🧪 Rendering hive-site.xml..."
envsubst < /opt/hive/conf/hive-site.xml.tmpl > /opt/hive/conf/hive-site.xml
envsubst < /opt/hive/conf/core-site.xml.tmpl > /opt/hive/conf/core-site.xml
echo 

# gosu hive and continue
echo "Starting HiveServer2 service..."

# Step 1: Generate a verbose Hive log4j2 config
touch $HIVE_HOME/conf/hive-log4j2.properties
cat > $HIVE_HOME/conf/hive-log4j2.properties <<EOF
status = WARN
name = HiveLogConfig

appender.console.type = Console
appender.console.name = STDOUT
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{ISO8601} [%t] %-5p %c %x - %m%n

appender.file.type = File
appender.file.name = FILE
appender.file.fileName = /opt/hive/logs/hive-server2.log
appender.file.layout.type = PatternLayout
appender.file.layout.pattern = %d{ISO8601} [%t] %-5p %c %x - %m%n

rootLogger.level = DEBUG
rootLogger.appenderRefs = stdout, file
rootLogger.appenderRef.stdout.ref = STDOUT
rootLogger.appenderRef.file.ref = FILE
EOF

set -x
export HIVE_SERVER2_OPTS="-Dlog4j.configurationFile=$HIVE_HOME/conf/hive-log4j2.properties"
export HIVE_METASTORE_URI=thrift://hive-metastore:9083

nohup $HIVE_HOME/bin/hive --service hiveserver2 > /opt/hive/logs/stdout.log 2>&1 &

# nohup $HIVE_HOME/bin/hive --service hiveserver2 > /opt/hive/logs/hiveserver2.out 2>&1 &
tail -f /dev/null
