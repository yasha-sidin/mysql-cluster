#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

for node in ${MYSQL_NODES}; do
  echo
  echo "--- ${node} ---"
  if ! mysqladmin ping -h "${node}" -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent >/dev/null 2>&1; then
    echo "${node} is unavailable"
    continue
  fi

  mysql -h "${node}" -uroot -p"${MYSQL_ROOT_PASSWORD}" --table -e "
    SELECT @@hostname AS node, @@read_only AS read_only, @@super_read_only AS super_read_only;
    SHOW TABLES FROM otus;
    SELECT COUNT(*) AS orders_count FROM otus.orders;
  "
done
