#!/bin/bash

# Prints messages in blue color for better visibility
function echoPlease() {
  echo -e "\n\e[1;34m$1\e[0m\n"
} 

# This script tests Trino connectivity and queries
echoPlease "Testing Trino connectivity and queries..."

# Test basic connectivity
echoPlease "Testing basic connectivity..."
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SELECT 1"

# List catalogs
echoPlease "Listing available catalogs..."
trino --server trino-coordinator:8080 --execute "SHOW CATALOGS"

# List schemas in hive catalog
echoPlease "Listing schemas in hive catalog..."
trino --server trino-coordinator:8080 --catalog hive --execute "SHOW SCHEMAS"

# List tables in default schema
echoPlease "Listing tables in default schema..."
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SHOW TABLES"

# Query the default table from Hive 
echoPlease "Querying Hive-catalog table --> [hive.airline.passenger_flights]"
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SELECT * FROM hive.airline.passenger_flights LIMIT 10"

# Query the Spark ETL output table from Hive 
echoPlease "Querying Hive-catalog table --> [hive.airline.passenger_flights_output]"
trino --server trino-coordinator:8080 --catalog hive --schema default --execute "SELECT * FROM hive.airline.passenger_flights_output LIMIT 10"

# Query the delta_products table created by Spark Deltalake ETL job
echoPlease "Querying Delta-catalog table --> [delta.default.delta_products]"
trino --server trino-coordinator:8080 --catalog delta --schema default --execute "SELECT * FROM delta.default.delta_products LIMIT 10"

echoPlease "Trino connectivity and query test completed successfully!"