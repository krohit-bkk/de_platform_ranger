# Download required jars
echo "Downloading required jars at - [/opt/bitnami/spark/jars]"


# Create directories for jars
mkdir -p /opt/bitnami/spark/jars

# S3 connector jars
curl -s https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.1/hadoop-aws-3.3.1.jar -o /opt/bitnami/spark/jars/hadoop-aws-3.3.1.jar
curl -s https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.901/aws-java-sdk-bundle-1.11.901.jar -o /opt/bitnami/spark/jars/aws-java-sdk-bundle-1.11.901.jar

# Delta Lake jars
curl -s https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.2.0/delta-core_2.12-2.2.0.jar -o /opt/bitnami/spark/jars/delta-core_2.12-2.2.0.jar
curl -s https://repo1.maven.org/maven2/io/delta/delta-storage/2.2.0/delta-storage-2.2.0.jar -o /opt/bitnami/spark/jars/delta-storage-2.2.0.jar