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
}

# Stop all services
function clean_all(){
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
  docker rmi -f $(docker images -q)
  # Remove all networks
  docker network prune -f
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

# FIRE UP DOCKER COMPOSE MANUALLY
# ===============================
# Base service
# docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-base.yml up -d 

# Vault service
# docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-vault.yml up -d && docker logs -f vault

# MinIO service
# docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-minio.yml up -d && docker logs -f minio

# Hive Metastore service
# docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-hive.yml up -d && docker logs -f hive-metastore

# HiveServer2 service
# docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-hive.yml up -d hiveserver2 && docker logs -f hiveserver2