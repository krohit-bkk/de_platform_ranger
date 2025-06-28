#!/bin/bash

# Prints messages in blue color for better visibility
function info() {
  echo -e "\n\e[1;34m$1\e[0m\n"
} 

curr_user=$(whoami)
info ">>>> User in action (inside init-schema.sh): $curr_user"

# This script initializes and starts Hive Metastore
info ">>>> Initializing Hive services..."

# Wait for PostgreSQL to be ready
info ">>>> Waiting for PostgreSQL to be ready..."
until pg_isready -h postgres -p 5432; do sleep 2; done

# Initialize schema if not exists
if [ ! -f /metastore/metastore_db/metastore.script ]; then
  info ">>>> Creating Hive metastore schema..."
  $HIVE_HOME/bin/schematool -dbType postgres -initSchema --verbose
fi

# Start Metastore in background with IS_RESUME
info ">>>> Starting Hive Metastore..."
export IS_RESUME="true"
$HIVE_HOME/bin/hive --service metastore &
sleep 10

# Create table with sample data - default.sample_table
# Sampel data created while launching MinIO S3 service - s3a://raw-data/airline_data/
cat <<EOF > sample_table.hql

CREATE DATABASE IF NOT EXISTS default;
CREATE DATABASE IF NOT EXISTS airline;

CREATE EXTERNAL TABLE IF NOT EXISTS airline.passenger_flights (
  PassengerID STRING,
  FirstName STRING,
  LastName STRING,
  Gender STRING,
  Age INT,
  Nationality STRING,
  AirportName STRING,
  AirportCountryCode STRING,
  CountryName STRING,
  AirportContinent STRING,
  Continents STRING,
  DepartureDate STRING,
  ArrivalAirport STRING,
  PilotName STRING,
  FlightStatus STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
ESCAPED BY '\\\\'
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION 's3a://raw-data/airline_data/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT * FROM airline.passenger_flights LIMIT 10;

EOF

cat sample_table.hql

# Create default schemas and tables
$HIVE_HOME/bin/hive -v -f sample_table.hql

info "\n\n>>>> Hive services started successfully!\nMetastore PID: $(pgrep -f 'metastore')\n\n"
