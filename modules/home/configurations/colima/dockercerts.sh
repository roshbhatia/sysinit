#!/usr/bin/env bash

# This script extracts system and Zscaler certificates, and copies all of them
# into Docker's certs.d directory for both Colima and Rancher Desktop, placing
# them in each domain's directory as required for Docker trusted CAs.

set -euo pipefail

COLIMA_CERTS_DIR="$HOME/.docker/certs.d"
RANCHER_CERTS_DIR="$HOME/Library/Application Support/rancher-desktop/lima/_config/certs/ca"
ZSCALER_CERT_PATH="$HOME/zscaler-certs/zscaler.pem"
DOCKER_DOMAINS=("registry-1.docker.io")

# Extract all system certs and copy to each domain's certs.d directory
extract_and_copy_system_certs_to_domains()
                                           {
    local base_dir="$1"
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
    security find-certificate -a -p /Library/Keychains/System.keychain > "$temp_dir/all_certs.pem"
    local cert_count
    cert_count=$(grep -c "BEGIN CERTIFICATE" "$temp_dir/all_certs.pem" || echo 0)
    [[ "$cert_count" -eq 0 ]] && {
                                   echo "No certificates found in system keychain" >&2
                                                                                        return 1
  }
    awk '/BEGIN CERTIFICATE/{if (cert) print cert > out; cert=""; n++; out=sprintf("'"$temp_dir"'/cert-%03d.pem", n)} {cert=cert $0 "\n"} END {if (cert) print cert > out}' "$temp_dir/all_certs.pem"
    local processed=0
    for domain in "${DOCKER_DOMAINS[@]}"; do
        local dest_dir="$base_dir/$domain"
        mkdir -p "$dest_dir"
        for cert_file in "$temp_dir"/cert-*.pem; do
            if openssl x509 -in "$cert_file" -noout 2> /dev/null; then
                local cert_name
                cert_name=$(openssl x509 -noout -subject -in "$cert_file" 2> /dev/null | sed -n 's/.*CN *= *\([^,]*\).*/\1/p' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-zA-Z0-9-._')
                [[ -z "$cert_name" ]] && cert_name="cert-$processed"
                cp "$cert_file" "$dest_dir/${cert_name}.crt"
                processed=$((processed + 1))
      fi
    done
  done
    echo "Copied $processed system certificates to $base_dir/<domain> directories."
}

# Copy Zscaler cert to each domain's certs.d directory
copy_zscaler_cert_to_domains()
                               {
    local base_dir="$1"
    for domain in "${DOCKER_DOMAINS[@]}"; do
        local dest_dir="$base_dir/$domain"
        mkdir -p "$dest_dir"
        if [[ -f "$ZSCALER_CERT_PATH" ]]; then
            cp "$ZSCALER_CERT_PATH" "$dest_dir/ca.crt"
            echo "Zscaler cert copied to $dest_dir/ca.crt"
    else
            echo "Zscaler certificate not found at $ZSCALER_CERT_PATH" >&2
    fi
  done
}

# Main logic
case "${1:-}" in
    colima)
        extract_and_copy_system_certs_to_domains "$COLIMA_CERTS_DIR"
        copy_zscaler_cert_to_domains "$COLIMA_CERTS_DIR"
        ;;
    rancher | rancher-desktop)
        extract_and_copy_system_certs_to_domains "$RANCHER_CERTS_DIR"
        copy_zscaler_cert_to_domains "$RANCHER_CERTS_DIR"
        ;;
    both | all)
        extract_and_copy_system_certs_to_domains "$COLIMA_CERTS_DIR"
        copy_zscaler_cert_to_domains "$COLIMA_CERTS_DIR"
        extract_and_copy_system_certs_to_domains "$RANCHER_CERTS_DIR"
        copy_zscaler_cert_to_domains "$RANCHER_CERTS_DIR"
        ;;
    *)
        echo "Usage: $0 {colima|rancher|rancher-desktop|both|all}"
        exit 1
        ;;
esac
