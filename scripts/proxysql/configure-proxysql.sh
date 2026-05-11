#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

echo "Waiting for ProxySQL admin ports..."
for proxy in ${PROXYSQL_NODES}; do
  until mysql -h "${proxy}" -P6032 -uradmin -pradmin -e "SELECT 1" >/dev/null 2>&1; do
    echo "  ${proxy} is not ready yet"
    sleep 2
  done

  echo "Configuring ${proxy}..."
  mysql -h "${proxy}" -P6032 -uradmin -pradmin < "${SCRIPT_DIR}/proxysql.sql"
done

echo "ProxySQL instances are configured."
