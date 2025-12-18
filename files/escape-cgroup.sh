#!/usr/bin/env bash
set -euo pipefail

# where your root cgroup is mounted
CGROUP_ROOT="/sys/fs/cgroup"
INIT_SCOPE="${CGROUP_ROOT}/init.scope"

# 1) create the init.scope directory if it doesn't exist
if [ ! -d "${INIT_SCOPE}" ]; then
  mkdir -p "${INIT_SCOPE}"
fi

# 2) for each pid in root cgroup, move it into init.scope
while read -r pid; do
  # skip any empty lines just in case
  if [[ -n "$pid" ]]; then
    echo "$pid" > "${INIT_SCOPE}/cgroup.procs"
  fi
done < "${CGROUP_ROOT}/cgroup.procs"

echo "All initial processes moved into ${INIT_SCOPE}/cgroup.procs"