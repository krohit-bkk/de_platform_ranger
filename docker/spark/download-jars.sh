set -euo pipefail

# Download required jars
echo "Downloading required jars at - [/opt/bitnami/spark/jars]"

# Create directories for jars
JAR_DIR="/opt/bitnami/spark/jars"
mkdir -p "$JAR_DIR"

# Associative array of jars with their download URLs
declare -A jars=(
  ["hadoop-aws-3.3.1.jar"]="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.1/hadoop-aws-3.3.1.jar"
  # ["aws-java-sdk-bundle-1.11.901.jar"]="https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.901/aws-java-sdk-bundle-1.11.901.jar" # Size 190 MB
  ["delta-core_2.12-2.2.0.jar"]="https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.2.0/delta-core_2.12-2.2.0.jar"
  ["delta-storage-2.2.0.jar"]="https://repo1.maven.org/maven2/io/delta/delta-storage/2.2.0/delta-storage-2.2.0.jar"
)

# Iterate over the array and download
for file in "${!jars[@]}"; do
  echo "Downloading ${file}..."
  curl --progress-bar -L "${jars[$file]}" -o "${JAR_DIR}/${file}"
done

echo "✅ All JARs downloaded to ${JAR_DIR}"
