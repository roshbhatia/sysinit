#!/usr/bin/env bash
set -e

CERT_CACHE="/tmp/colima-cert-cache"
CERT_HASH_FILE="/tmp/colima-cert-hash"

run_in_colima() {
  @colima@/bin/colima ssh -- "$@" 2>/dev/null || true
}

wait_for_colima() {
  local max_attempts=30
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    if @colima@/bin/colima status >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
    attempt=$((attempt + 1))
  done

  exit 0
}

get_cert_hash() {
  security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain 2>/dev/null | shasum -a 256 | cut -d' ' -f1
}

update_certificates() {
  local current_hash=$(get_cert_hash)
  local cached_hash=""

  if [ -f "$CERT_HASH_FILE" ]; then
    cached_hash=$(cat "$CERT_HASH_FILE")
  fi

  if [ "$current_hash" = "$cached_hash" ] && [ -f "$CERT_CACHE" ]; then
    return 0
  fi

  echo "$current_hash" >"$CERT_HASH_FILE"

  security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain >"$CERT_CACHE" 2>/dev/null || true

  if [ -f "$CERT_CACHE" ] && [ -s "$CERT_CACHE" ]; then
    cp "$CERT_CACHE" /tmp/colima/macos-certs.pem 2>/dev/null || true

    run_in_colima "sudo cp /tmp/colima/macos-certs.pem /etc/ssl/certs/ca-certificates.crt" || true
    run_in_colima "sudo update-ca-certificates" || true

    run_in_colima "sudo mkdir -p /etc/docker" || true
    cat >/tmp/colima/daemon.json <<'EOF'
{
  "insecure-registries": [
    "xpkg.upbound.io",
    "xpkg.crossplane.io",
    "artifactory.nike.com:9001"
  ],
  "registry-mirrors": [],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "tlscacert": "/etc/ssl/certs/ca-certificates.crt",
  "tlsverify": true
}
EOF
    run_in_colima "sudo cp /tmp/colima/daemon.json /etc/docker/daemon.json" || true
    run_in_colima "sudo systemctl restart docker" || run_in_colima "sudo service docker restart" || true
  fi
}

wait_for_colima
update_certificates
rm -f /tmp/colima/macos-certs.pem /tmp/colima/daemon.json 2>/dev/null || true
