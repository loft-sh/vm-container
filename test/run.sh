#!/usr/bin/env bash
# Boots the image with a NoCloud seed and checks ssh behavior. Usage: test/run.sh <image>
set -euo pipefail

IMAGE=${1:?usage: $0 <image>}
WORK=$(mktemp -d)
CONTAINER=""

cleanup() {
  [[ -n "$CONTAINER" ]] && docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o BatchMode=yes -o LogLevel=ERROR -o ConnectTimeout=5)

# start_container <seed-dir>; sets CONTAINER and IP once cloud-init has finished
start_container() {
  [[ -n "$CONTAINER" ]] && docker rm -f "$CONTAINER" >/dev/null
  CONTAINER=$(docker run -d --privileged --tmpfs /run -v "$1:/var/lib/cloud/seed/nocloud:ro" "$IMAGE")
  for _ in $(seq 60); do
    if docker exec "$CONTAINER" cloud-init status 2>/dev/null | grep -qE 'status: (done|error)'; then break; fi
    sleep 2
  done
  docker exec "$CONTAINER" cloud-init status --long | grep -q 'status: done' ||
    { docker exec "$CONTAINER" cloud-init status --long || true; docker logs "$CONTAINER" | tail -50; return 1; }
  IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER")
}

seed() {
  mkdir -p "$1"
  echo '{"instance-id": "test"}' >"$1/meta-data"
  cat >"$1/user-data"
}

test_user_ssh_key() {
  echo "=== user ssh key from user-data"
  ssh-keygen -q -t ed25519 -N '' -f "$WORK/user_key"
  seed "$WORK/seed1" <<EOT
#cloud-config
users:
- name: tester
  shell: /bin/bash
  ssh_authorized_keys:
  - $(cat "$WORK/user_key.pub")
EOT
  start_container "$WORK/seed1"
  local nonce=$RANDOM$RANDOM
  local out
  out=$(ssh "${SSH_OPTS[@]}" -i "$WORK/user_key" "tester@$IP" "echo $nonce; id -un")
  [[ "$out" == "$nonce"$'\n'"tester" ]] || { echo "unexpected ssh output: $out"; return 1; }
}

test_host_key_override() {
  echo "=== host key override from user-data"
  ssh-keygen -q -t ed25519 -N '' -f "$WORK/host_key"
  seed "$WORK/seed2" <<EOT
#cloud-config
ssh_deletekeys: true
ssh_keys:
  ed25519_private: |
$(sed 's/^/    /' "$WORK/host_key")
  ed25519_public: $(cat "$WORK/host_key.pub")
EOT
  start_container "$WORK/seed2"
  local want got
  want=$(ssh-keygen -lf "$WORK/host_key.pub" | awk '{print $2}')
  got=$(ssh-keyscan -T 5 -t ed25519 "$IP" 2>/dev/null | ssh-keygen -lf - | awk '{print $2}')
  [[ -n "$got" && "$got" == "$want" ]] || { echo "host key mismatch: want $want got $got"; return 1; }
}

test_user_ssh_key
test_host_key_override
echo "PASS"
