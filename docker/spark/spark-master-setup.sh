#!/bin/bash

# Blue info log
function info() {
  echo -e "\n\e[1;34m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

# This script sets up the Spark environment with necessary jars for S3, Hive, and Delta Lake
source /opt/setup-env.sh 
# source /opt/download-jars.sh  # Baked in custom-spark image

info "\nHMS_URI: ${HMS_URI}\n"

# 🧪 Render hive-site.xml dynamically
info "🧪 Rendering spark-defaults.xml... \n"
envsubst < /opt/bitnami/spark/conf/spark-defaults.xml.tmpl > /opt/bitnami/spark/conf/spark-defaults.xml

info "Spark environment setup completed successfully!"