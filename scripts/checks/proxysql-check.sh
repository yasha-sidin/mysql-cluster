#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

for proxy in ${PROXYSQL_NODES}; do
  echo
  echo "--- ${proxy} ---"
  mysql -h "${proxy}" -P6033 -u"${MYSQL_APP_USER}" -p"${MYSQL_APP_PASSWORD}" --table <<SQL
INSERT INTO otus.route_probe(client_name, target_host) VALUES ('${proxy}', @@hostname);
DO SLEEP(1);
SELECT '${proxy}' AS proxy, @@hostname AS node_used_for_read;
SELECT id, client_name, target_host AS node_used_for_write, created_at
FROM otus.route_probe
ORDER BY id DESC
LIMIT 5;
SQL
done
