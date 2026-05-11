#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../common/env.sh"

NODE="${1:-}"
if [ -z "${NODE}" ]; then
  echo "Usage: bash /scripts/cluster/rejoin-node.sh db1"
  exit 1
fi

REJOIN_NODE="${NODE}" mysqlsh --js --file "${SCRIPT_DIR}/rejoin-node.js"
