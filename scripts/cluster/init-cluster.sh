#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

if ! command -v mysqlsh >/dev/null 2>&1; then
  echo "mysqlsh is required in the admin container"
  exit 1
fi

echo "Waiting for MySQL nodes..."
for node in ${MYSQL_NODES}; do
  until mysqladmin ping -h "${node}" -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent >/dev/null 2>&1; do
    echo "  ${node} is not ready yet"
    sleep 3
  done
  echo "  ${node} is ready"
done

echo "Creating or updating InnoDB Cluster..."
mysqlsh --js --file "${SCRIPT_DIR}/init-cluster.js"
