from pyspark.sql import SparkSession

# Sample PySpark ETL job that reads data from a Hive table and displays it
def main():
  # Initialize SparkSession with Hive support
  spark = SparkSession.builder \
    .appName("Simple PySpark ETL") \
    .enableHiveSupport() \
    .getOrCreate()

  # Table names
  input_table = "airline.passenger_flights"
  output_table = "airline.passenger_flights_output"

  # Read table from Hive
  df = spark.table(input_table)
  print(f"\n>>>> Number of records in the table: {df.count()}\n")
  # Show data on console
  df.show(truncate=False)

  # Write to Hive table
  df.write \
    .mode("overwrite") \
    .saveAsTable(output_table)
  print(f"\n>>>> Wrote output to table: [{output_table}]\n")
  
  # Read the output table to verify
  print(f"\n>>>> Reading output table from Hive: [{output_table}]\n")
  df = spark.table(output_table)
  df.show(truncate=False)
  print(f"\n>>>> Number of records in output table in Hive [{output_table}]: {df.count()}\n")

  print("\n>>>> Read/Write ops with hive completed successfully.\nClosign application...\n")

  # Stop SparkSession
  spark.stop()

if __name__ == "__main__":
  main()