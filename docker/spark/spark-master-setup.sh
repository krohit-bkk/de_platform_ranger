#!/bin/bash

# This script sets up the Spark environment with necessary jars for S3, Hive, and Delta Lake
source /opt/bitnami/setup-env.sh
source /opt/bitnami/download-jars.sh

echo -e "\nHMS_URI: ${HMS_URI}\n"

# 🧪 Render hive-site.xml dynamically
echo -e "🧪 Rendering spark-defaults.xml... \n"
envsubst < /opt/bitnami/spark/conf/spark-defaults.xml.tmpl > /opt/bitnami/spark/conf/spark-defaults.xml

echo "Spark environment setup completed successfully!"