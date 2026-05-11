#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

PREFERRED_NODES=(db5 db4 db3 db2 db1)
SOURCE=""
PRIMARY_FALLBACK=""

for node in "${PREFERRED_NODES[@]}"; do
  role="$(mysql -h "${node}" -u"${MYSQL_BACKUP_USER}" -p"${MYSQL_BACKUP_PASSWORD}" --batch --skip-column-names -e "
    SELECT MEMBER_ROLE
    FROM performance_schema.replication_group_members
    WHERE MEMBER_ID = @@server_uuid AND MEMBER_STATE = 'ONLINE';
  " 2>/dev/null || true)"

  if [ "${role}" = "SECONDARY" ]; then
    SOURCE="${node}"
    break
  fi

  if [ "${role}" = "PRIMARY" ] && [ -z "${PRIMARY_FALLBACK}" ]; then
    PRIMARY_FALLBACK="${node}"
  fi
done

if [ -z "${SOURCE}" ]; then
  SOURCE="${PRIMARY_FALLBACK}"
fi

if [ -z "${SOURCE}" ]; then
  echo "No online MySQL node is available for backup"
  exit 1
fi

BACKUP_NAME="otus-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${BACKUP_WORKDIR}"
WORK_DIR="$(mktemp -d "${BACKUP_WORKDIR}/otus-backup.XXXXXX")"
TARGET="${WORK_DIR}/${BACKUP_NAME}"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

echo "Backup source: ${SOURCE}"
echo "Volume dump target: ${TARGET}"

BACKUP_SOURCE="${SOURCE}" BACKUP_TARGET="${TARGET}" mysqlsh --js --file "${SCRIPT_DIR}/dump-schema.js"

upload_to_minio() {
  local alias_name="$1"
  local endpoint="$2"
  local attempt

  echo "Uploading dump to ${alias_name}..."
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if mc alias set "${alias_name}" "${endpoint}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" >/dev/null 2>&1; then
      mc mb --ignore-existing "${alias_name}/${BACKUP_BUCKET}" >/dev/null
      mc cp --recursive "${TARGET}/" "${alias_name}/${BACKUP_BUCKET}/${BACKUP_NAME}/"
      echo "  ${alias_name}: ${BACKUP_BUCKET}/${BACKUP_NAME}/"
      return 0
    fi

    echo "  ${alias_name} is not ready yet (${attempt}/10)"
    sleep 2
  done

  echo "  ${alias_name}: upload skipped, storage is unavailable"
  return 1
}

echo "Saving backup to MinIO:"
UPLOADS=0
if upload_to_minio minio-a "${MINIO_A_ENDPOINT}"; then
  UPLOADS=$((UPLOADS + 1))
fi

if upload_to_minio minio-b "${MINIO_B_ENDPOINT}"; then
  UPLOADS=$((UPLOADS + 1))
fi

if [ "${UPLOADS}" -eq 0 ]; then
  echo "Backup was created, but no MinIO storage accepted it"
  exit 1
fi

echo "Backup upload copies: ${UPLOADS}"
