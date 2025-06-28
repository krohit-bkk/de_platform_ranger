# PROJECT SETUP
# =============

# Project root folder
export PROJECT_ROOT=$(dirname "$(realpath "$0")")
cd ${PROJECT_ROOT}
echo -e "
  PROJECT ROOT
  ============
  Project root     : ${PROJECT_ROOT}
  Current directory: $(pwd)
"

# Process .env file 
envsubst < ${PROJECT_ROOT}/.env | tee ${PROJECT_ROOT}/.env.evaluated

# Create base directories
install -d -m 775 "$PROJECT_ROOT"/data
mkdir -p "${PROJECT_ROOT}/data"/{minio_data,postgres_hms_data,hive_hs2_data,hive_data,postgres_ranger_data,vault_data,spark_data,trino_data,airflow_data,superset_data}
chmod -R 777 "${PROJECT_ROOT}/data"/{minio_data,postgres_hms_data,hive_hs2_data,hive_data,postgres_ranger_data,vault_data,spark_data,trino_data,airflow_data,superset_data}

# HMS and HS2 directories maps to HDFS dir inside container - /tmp/hive 
install -d -m 777 "${PROJECT_ROOT}/data/hive_data/hive-tmp"
install -d -m 777 "${PROJECT_ROOT}/data/hive_hs2_data/hive-tmp"
chmod -R 777 ${PROJECT_ROOT}/data/hive_data
chmod -R 777 ${PROJECT_ROOT}/data/hive_hs2_data

echo -e "
  Directories created
  ===================
  Data directory: ${PROJECT_ROOT}/data
  Subdirectories created:
    - minio_data
    - postgres_hms_data
    - postgres_ranger_data
    - vault_data
    - spark_data
    - trino_data
    - airflow_data
    - superset_data
    - data/hive_data/hive-tmp"
ls -lrt ${PROJECT_ROOT}/data/


# Execute permissions for Spark jobs
sudo chmod +x ${PROJECT_ROOT}/docker/spark/spark-master-setup.sh
sudo chmod +x ${PROJECT_ROOT}/docker/spark/spark-worker-setup.sh
sudo chmod +x ${PROJECT_ROOT}/docker/trino/setup-coordinator.sh
sudo chmod +x ${PROJECT_ROOT}/docker/trino/setup-worker.sh
sudo chmod +x ${PROJECT_ROOT}/docker/trino/jobs/trino-test.sh

# DOCKER UTILS
# ============
# Create docker functions and aliases
alias psa='docker ps -a'
alias rma='docker rm -f $(docker ps -aq)'
alias images='docker images'
alias networks='docker network ls'
alias volumes='docker volume ls'
alias logs='docker logs -f'

# List all containers, images, volumes and networks
function all(){
  # List all containers
  psa 
  echo
  #List all images
  images
  echo
  # List all volumes
  volumes
  echo 
  # List all networks
  networks
}

# Start all services
function start_all(){
  # Base service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-base.yml up -d 
  sleep 5

  # Vault service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-vault.yml up -d
  sleep 10

  # MinIO service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-minio.yml up -d
  sleep 10

  # Hive (HMS + HS2) services
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-hive.yml up -d
  sleep 10

  # Build custom-spark image and start Spark services
  # docker build --no-cache -t custom-spark:0.0.1 ${PROJECT_ROOT}/docker/spark/
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-spark.yml up -d spark-master spark-worker-1 spark-worker-2

  # Trino services
  # docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-trino.yml up -d trino-coordinator trino-worker-1 trino-worker-2
}

# Stop all services
function clean_all(){
  # Stop Trino services
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-trino.yml down -v
  sleep 3

  # Spark service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-spark.yml down -v
  sleep 3

  # Hive Metastore service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-hive.yml down -v
  sleep 3

  # MinIO service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-minio.yml down -v
  sleep 3

  # Vault service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-vault.yml down -v
  sleep 3

  # Base service
  docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-base.yml down -v
}


# Remove all containers, images, networks, and volumes
function wipe_everything(){
  # Remove all containers
  rma
  # Remove all images
  # docker rmi -f $(docker images -q)
  # Remove all networks
  docker network prune -f
  # Remoce data folder for mounts
  sudo rm -rf ${PROJECT_ROOT}/data
}

# Kill services... 
# Usage: kill_service <service_name1> <service_name2> ...
function kill_service() {
  for svc in "$@"; do
    echo "Handling service: $svc"

    # Get PID of the container
    svc_pid=$(docker inspect -f '{{.State.Pid}}' "$svc" 2>/dev/null)

    if [[ -n "$svc_pid" && "$svc_pid" =~ ^[0-9]+$ ]]; then
      echo "Killing PID $svc_pid for $svc"
      sudo kill -9 "$svc_pid" 2>/dev/null || true
    else
      echo "Could not find PID for $svc or container is not running."
    fi

    echo "Removing container $svc"
    sudo docker rm -f "$svc" 2>/dev/null || echo "Failed to remove $svc"

    # Remove associated volumes if service is postgres or minio
    # if [[ "$svc" =~ postgres|minio ]]; then
    if [[ "$svc" =~ postgres ]]; then
      echo "Pruning unused volumes for $svc"
      sudo docker volume prune -f 2>/dev/null || true

      if [[ "$svc" == "postgres" ]]; then
        echo "Cleaning Hive-Metastore PostgreSQL data directory..."
        sudo rm -rf "${PROJECT_ROOT}/data/postgres_hms_data"
        sudo install -d -m 777 "${PROJECT_ROOT}/data/postgres_hms_data"
      fi
    fi
    echo ""
  done
}

# FIRE UP DOCKER COMPOSE/SERVICES MANUALLY
# ========================================
# Base service
alias start_base="docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-base.yml up -d "

# Vault service
alias start_vault="docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-vault.yml up -d && logs -f vault"

# MinIO service
alias start_minio="docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-minio.yml up -d && logs -f minio"

# Hive Metastore service
alias start_hms="docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-hive.yml up -d && logs -f hive-metastore"

# HiveServer2 service
alias start_hs2="docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-hive.yml up -d hiveserver2 && logs -f hiveserver2"

# Test Spark ETL jobs
alias spark_test="docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-spark.yml up -d spark-test && logs -f spark-test"
alias deltalake_test="docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-spark.yml up -d delta-lake-test && logs -f delta-lake-test"

# Create custom docker images
# ===========================
# docker build --no-cache -t custom-spark ${PROJECT_ROOT}/docker/spark/

# OPTIONAL: Keep local copy of JAR files for quick dev and testing
# ================================================================
# # S3 connector jars
# curl -s https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.1/hadoop-aws-3.3.1.jar -o ${PROJECT_ROOT}/docker/spark/lib/hadoop-aws-3.3.1.jar
# curl -s https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.901/aws-java-sdk-bundle-1.11.901.jar -o ${PROJECT_ROOT}/docker/spark/lib/aws-java-sdk-bundle-1.11.901.jar

# # Delta Lake jars
# curl -s https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.2.0/delta-core_2.12-2.2.0.jar -o ${PROJECT_ROOT}/docker/spark/lib/delta-core_2.12-2.2.0.jar
# curl -s https://repo1.maven.org/maven2/io/delta/delta-storage/2.2.0/delta-storage-2.2.0.jar -o ${PROJECT_ROOT}/docker/spark/lib/delta-storage-2.2.0.jar

# # Hive Service Related jars
# cp ${PROJECT_ROOT}/docker/spark/lib/aws-java-sdk-bundle-1.11.901.jar -o ${PROJECT_ROOT}/docker/hive/lib/aws-java-sdk-bundle-1.11.901.jar
# curl -s https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar -o ${PROJECT_ROOT}/docker/hive/lib/hadoop-aws-3.2.0.jar
# curl -s https://repo1.maven.org/maven2/org/postgresql/postgresql/42.3.1/postgresql-42.3.1.jar -o ${PROJECT_ROOT}/docker/hive/lib/postgresql-42.3.1.jar 