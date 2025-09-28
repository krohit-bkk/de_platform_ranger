#!/bin/bash
set -e
# Blue info log
function info() {
  echo -e "\n\e[1;34m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

info "📦 Creating buckets..."

mc alias set myminio http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

for bucket in raw transformed curated; do
  mc mb --ignore-existing "myminio/${bucket}-data"
done

# Moving sample data to raw-data bucket
mc cp --recursive /sample_data/ "myminio/raw-data/"
mc ls myminio/raw-data/

# Upload a sample file
echo "1,A,Foo" >> sample-file.csv
echo "2,B,Bar" >> sample-file.csv

# Create logs history bucket for Spark history server
mc mb myminio/spark-logs --ignore-existing
# Create a "folder" by uploading an empty file to the spark-events path
touch empty.txt
mc cp empty.txt myminio/spark-logs/spark-events/
mc cp sample-file.csv myminio/spark-logs/spark-events/
mc ls myminio/spark-logs/spark-events/

info "🎉 Buckets created"