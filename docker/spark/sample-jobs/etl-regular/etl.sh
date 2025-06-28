#!/bin/bash

# Blue info log
function info() {
  echo -e "\n\e[1;34m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

# This script tests the Spark ETL job
info "Testing Spark ETL job..."

# Setup environment variables
source /opt/setup-env.sh
info "\nHMS_URI: ${HMS_URI}\n"

# Wait for Spark master to be ready
info "Waiting for Spark master to be ready..."
while ! nc -z spark-master 7077 >/dev/null; do
  info "[$(date '+%Y-%m-%d %H:%M:%S')] - Spark master is not up yet! Checked at [spark-master:7077]. Retrying in 10 seconds..."
  sleep 10
done
info "[$(date '+%Y-%m-%d %H:%M:%S')] - Spark master is up at [spark-master:7077]! \n"

# Submit the sample ETL job
info "Submitting sample ETL job...\n"
/opt/bitnami/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  --conf spark.jars.ivy=/tmp/.ivy \
  --conf spark.sql.catalogImplementation=hive \
  --conf "spark.hadoop.hive.metastore.uris=${HMS_URI}" \
  --conf "spark.hadoop.fs.s3a.endpoint=${MINIO_ENDPOINT}" \
  --conf "spark.sql.warehouse.dir=${SPARK_SQL_WAREHOUSE_DIR}" \
  --conf "spark.hadoop.fs.s3a.access.key=${MINIO_ROOT_USER}" \
  --conf "spark.hadoop.fs.s3a.secret.key=${MINIO_ROOT_PASSWORD}" \
  --conf "spark.hadoop.fs.s3a.path.style.access=true" \
  --conf "spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem" \
  --conf "spark.hadoop.fs.s3a.connection.ssl.enabled=false" \
  --conf "spark.driver.extraJavaOptions=-Dlog4j.rootCategory=WARN,console" \
  --conf "spark.driver.extraJavaOptions=-Dlog4j.configuration=file:/opt/bitnami/spark/conf/log4j.properties" \
  /opt/spark/jobs/etl-regular/etl.py

if [ $? -eq "0" ]; then 
  info "Spark ETL job test completed!"
  exit 0
fi 

info ">>>> Spark ETL job failed! I'll be live for 5 min so that you can debug..."
sleep 300
exit 1