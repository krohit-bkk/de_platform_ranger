#!/bin/bash

# Blue info log
function info() {
  echo -e "\n\e[1;34m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

# Yellow warning log
function warn() {
  echo -e "\n\e[1;33m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}

# Red fatal log
function fatal() {
  echo -e "\n\e[1;31m[$(date '+%Y-%m-%d %H:%M:%S')] - $1\e[0m\n"
}


# This script tests Trino connectivity and queries
info "Testing Trino connectivity and queries..."

# Test basic connectivity
info "Testing basic connectivity..."
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SELECT 1"

# List catalogs
info "Listing available catalogs..."
trino --server trino-coordinator:8080 --execute "SHOW CATALOGS"

# List schemas in hive catalog
info "Listing schemas in hive catalog..."
trino --server trino-coordinator:8080 --catalog hive --execute "SHOW SCHEMAS"

# List tables in default schema
info "Listing tables in default schema..."
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SHOW TABLES"

# Query the default table from Hive 
info "Querying Hive-catalog table --> [hive.airline.passenger_flights]"
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SELECT * FROM hive.airline.passenger_flights LIMIT 10"

# Query the Spark ETL output table from Hive 
info "Querying Hive-catalog table --> [hive.airline.passenger_flights_output]"
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SELECT * FROM hive.airline.passenger_flights_output LIMIT 10"

# Query the delta_products table created by Spark Deltalake ETL job
info "Querying Delta-catalog table --> [delta.default.delta_products]"
trino --server trino-coordinator:8080 --catalog delta --schema default --execute "SELECT * FROM delta.default.delta_products LIMIT 10"

info "Trino connectivity and query test completed successfully!"