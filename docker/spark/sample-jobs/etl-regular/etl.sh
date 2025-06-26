#!/bin/bash

# This script tests the Spark ETL job
echo "Testing Spark ETL job..."

# Setup environment variables
source /opt/bitnami/setup-env.sh

# Wait for Spark master to be ready
echo "Waiting for Spark master to be ready..."
while ! nc -z spark-master 7077 >/dev/null; do
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] - Spark master is not up yet! Checked at [spark-master:7077]. Retrying in 10 seconds..."
  sleep 10
done
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] - Spark master is up at [spark-master:7077]! \n"

# Submit the sample ETL job
echo -e "Submitting sample ETL job...\n"
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
  echo "Spark ETL job test completed!"
  exit 0
fi 

echo ">>>> Spark ETL job failed! I'll be live for 5 min so that you can debug..."
sleep 300
exit 1