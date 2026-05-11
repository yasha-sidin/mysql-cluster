FROM minio/mc:latest AS minio-client

FROM container-registry.oracle.com/mysql/community-server:8.0

COPY --from=minio-client /usr/bin/mc /usr/local/bin/mc

