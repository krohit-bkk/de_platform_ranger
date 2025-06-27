FROM bitnami/spark:3.3.0

USER root

# Install necessary packages
RUN install_packages curl jq gettext netcat

# Copy your setup script(s)
COPY setup-env.sh /opt/setup-env.sh
COPY download-jars.sh /opt/download-jars.sh
RUN chmod +x /opt/setup-env.sh
RUN chmod +x /opt/download-jars.sh

# Direct copy of big jar file - 190 MB
COPY ./lib/aws-java-sdk-bundle-1.11.901.jar /opt/bitnami/spark/jars/aws-java-sdk-bundle-1.11.901.jar

# Run the setup script during build
RUN /opt/download-jars.sh