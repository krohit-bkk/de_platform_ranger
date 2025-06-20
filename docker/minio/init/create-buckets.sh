#!/bin/sh
set -e

echo "📦 Creating buckets..."

mc alias set myminio http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

for bucket in raw transformed curated; do
  mc mb --ignore-existing "myminio/${bucket}-data"
done

# Moving sample data to raw-data bucket
mc cp --recursive /sample_data/ "myminio/raw-data/"
mc ls myminio/raw-data/

echo "🎉 Buckets created"
