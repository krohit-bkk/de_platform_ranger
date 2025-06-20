FROM debian:bullseye-slim

# Install basic packages
RUN apt-get update && \
  apt-get install -y \
    curl \
    wget \
    ca-certificates \
    jq \
    grep \
    sed \
    bash \
    procps && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install MinIO server
RUN curl -L https://dl.min.io/server/minio/release/linux-amd64/archive/minio.RELEASE.2025-05-24T17-08-30Z -o /usr/local/bin/minio && \
  chmod +x /usr/local/bin/minio

# Install MinIO client
RUN curl -L https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc && \
  chmod +x /usr/local/bin/mc

# Copy your custom entrypoint script if needed
COPY ./init/entrypoint.sh /entrypoint.sh
COPY ./init/create-buckets.sh /create-buckets.sh
RUN chmod +x /entrypoint.sh /create-buckets.sh

ENTRYPOINT ["/entrypoint.sh"]
