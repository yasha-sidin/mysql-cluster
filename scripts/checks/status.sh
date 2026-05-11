#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

echo "=== InnoDB Cluster status ==="
mysqlsh --js --file "${SCRIPT_DIR}/status.js"

echo
echo "=== Group Replication view from each node ==="
for node in ${MYSQL_NODES}; do
  echo
  echo "--- ${node} ---"
  if ! mysqladmin ping -h "${node}" -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent >/dev/null 2>&1; then
    echo "${node} is unavailable"
    continue
  fi

  mysql -h "${node}" -uroot -p"${MYSQL_ROOT_PASSWORD}" --table -e "
    SELECT @@hostname AS node, @@read_only AS read_only, @@super_read_only AS super_read_only;
    SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE
    FROM performance_schema.replication_group_members
    ORDER BY MEMBER_HOST;
  "
done
