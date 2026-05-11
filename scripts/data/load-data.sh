#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

echo "Loading demo data through proxysql1..."
mysql -h proxysql1 -P6033 -u"${MYSQL_APP_USER}" -p"${MYSQL_APP_PASSWORD}" < "${SCRIPT_DIR}/load-data.sql"
