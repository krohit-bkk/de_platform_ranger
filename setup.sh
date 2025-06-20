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
chmod -R 775 "${PROJECT_ROOT}/data"/{minio_data,postgres_hms_data,hive_hs2_data,hive_data,postgres_ranger_data,vault_data,spark_data,trino_data,airflow_data,superset_data}
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



# DOCKER UTILS
# ============
# Create docker functions and aliases
alias psa='docker ps -a'
alias rma='docker rm -f $(docker ps -aq)'
alias images='docker images'
alias networks='docker network ls'
alias volumes='docker volume ls'

function all(){
  # List all containers
  psa 
  echo
  #List all images
  images
  echo
  # List all networks
  networks
  echo 
  # List all volumes
  volumes
}

function clean(){
  # Remove all containers
  rma
  # Remove all images
  docker rmi -f $(docker images -q)
  # Remove all networks
  docker network prune -f
}

function kill_vault(){
  # Find PID of the container
  vault_pid=$(docker inspect -f '{{.State.Pid}}' vault)
  kill -9 "$vault_pid" 2>/dev/null || true

  # Remove the container
  docker rm -f vault 2>/dev/null || true
}

function kill_service(){
  svc=${1}
  # Find PID of the container
  svc_pid=$(docker inspect -f '{{.State.Pid}}' ${svc})
  sudo kill -9 "$svc_pid" 2>/dev/null || true

  # Remove the container
  sudo docker rm -f ${svc} 2>/dev/null || true
}

# FIRE UP DOCKER COMPOSE
# ======================
# Base service
docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-base.yml up -d 

# Vault service
docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-vault.yml up -d && docker logs -f vault

# MinIO service
docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-minio up -d && docker logs -f minio

# Hive Metastore service
docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-hive-metastore.yml up -d && docker logs -f hive-metastore

# HiveServer2 service
docker-compose --env-file .env.evaluated -f ./docker-compose/docker-compose-metastore.yml up -d hiveserver2 && docker logs -f hiveserver2