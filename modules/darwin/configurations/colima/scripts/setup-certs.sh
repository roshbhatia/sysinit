#!/usr/bin/env bash
set -e

# Setup script for Colima certificates and Docker configuration
run_in_colima() {
  @colima@/bin/colima ssh -- "$@" 2>/dev/null || true
}

# Wait for Colima to be ready, exit gracefully if not available
if ! @colima@/bin/colima status >/dev/null 2>&1; then
  sleep 10
  if ! @colima@/bin/colima status >/dev/null 2>&1; then
    exit 0
  fi
fi

# Export and copy macOS certificates
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain >/tmp/macos-certs.pem 2>/dev/null || true
mkdir -p /tmp/colima

if [ -f /tmp/macos-certs.pem ]; then
  cp /tmp/macos-certs.pem /tmp/colima/ 2>/dev/null || true
  run_in_colima "sudo cat /tmp/colima/macos-certs.pem >> /etc/ssl/certs/ca-certificates.crt" || true
  run_in_colima "sudo update-ca-certificates" || true
fi

# Configure Docker daemon with insecure registries
run_in_colima "sudo mkdir -p /etc/docker" || true
cat >/tmp/colima/daemon.json <<'EOF'
{
  "insecure-registries": [
    "xpkg.crossplane.io",
    "artifactory.nike.com:9001"
  ]
}
EOF
run_in_colima "sudo cp /tmp/colima/daemon.json /etc/docker/daemon.json" || true
run_in_colima "sudo systemctl restart docker" || run_in_colima "sudo service docker restart" || true

# Cleanup temporary files
rm -f /tmp/macos-certs.pem /tmp/colima/macos-certs.pem /tmp/colima/daemon.json 2>/dev/null || true
