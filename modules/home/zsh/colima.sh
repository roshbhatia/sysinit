#!/usr/bin/env zsh
# shellcheck disable=all

# Set Docker to always pull multi-architecture images
export DOCKER_DEFAULT_PLATFORM=linux/amd64,linux/arm64

# Colima recreation with progress indicators
colima.recreate() {
    # Directory configurations
    local CA_CERTS_DIR="/usr/local/share/ca-certificates"
    local DOCKER_CERTS_DIR="$HOME/.docker/certs.d"
    local COLIMA_CONFIG_DIR="$HOME/.colima"

    # Check for required commands
    for cmd in colima security openssl sudo; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            gum style --foreground "#ff0000" "Required command '$cmd' not found"
            return 1
        fi
    done

    # Create temp directory with cleanup trap
    local temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Delete existing Colima instance
    if colima status &>/dev/null; then
        gum spin --spinner dot --title "Deleting existing Colima instance..." -- colima delete -f
    fi

    gum spin --spinner dot --title "Setting up certificate directories..." -- bash -c "
        rm -rf '$COLIMA_CONFIG_DIR' &&
        sudo mkdir -p '$CA_CERTS_DIR' '$DOCKER_CERTS_DIR'"

    # Extract and process certificates
    gum spin --spinner dot --title "Extracting CA certificates..." -- \
        security find-certificate -a -p /Library/Keychains/System.keychain > "$temp_dir/all_certs.pem"

    local cert_count=$(grep -c "BEGIN CERTIFICATE" "$temp_dir/all_certs.pem" || echo 0)
    gum style "Found $cert_count certificates in keychain"

    if [ "$cert_count" -eq 0 ]; then
        gum style --foreground "#ff0000" "No certificates found in system keychain"
        return 1
    fi

    # Process certificates with progress bar
    gum spin --spinner dot --title "Processing certificates..." -- bash -c "
        awk '
            /BEGIN CERTIFICATE/{
                if (cert) print cert > out
                cert = \"\"
                n++
                out = sprintf(\"$temp_dir/cert-%03d.pem\", n)
            }
            { cert = cert \$0 \"\\n\" }
            END { if (cert) print cert > out }
        ' \"$temp_dir/all_certs.pem\""

    local processed=0
    for cert_file in "$temp_dir"/cert-*.pem; do
        if openssl x509 -in "$cert_file" -noout 2>/dev/null; then
            local cert_subject=$(openssl x509 -noout -subject -in "$cert_file" 2>/dev/null)
            local cert_name=$(echo "$cert_subject" | sed -n 's/.*CN *= *\([^,]*\).*/\1/p' | \
                            tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-zA-Z0-9-._')
            
            if [[ -z "$cert_name" ]]; then
                cert_name="cert-$processed"
            fi

            if sudo cp "$cert_file" "$CA_CERTS_DIR/${cert_name}.pem" &&
               sudo openssl x509 -outform der -in "$cert_file" -out "$DOCKER_CERTS_DIR/${cert_name}.crt"; then
                ((processed++))
            fi
        fi
    done

    gum style "Successfully processed $processed certificates"

    # Start Colima with progress indication
    gum spin --spinner dot --title "Starting Colima..." -- \
        colima start --cpu 6 --memory 12 --dns 8.8.8.8 --vz-rosetta -V "$CA_CERTS_DIR"

    # Update CA certificates in Colima
    gum spin --spinner dot --title "Updating CA certificates in Colima..." -- \
        colima ssh -- sudo update-ca-certificates

    # Set up Docker socket
    gum spin --spinner dot --title "Setting up Docker socket..." -- bash -c "
        sudo rm -f /var/run/docker.sock &&
        sudo ln -s '$HOME/.config/colima/default/docker.sock' /var/run/docker.sock"

    gum style --foreground "#00ff00" "✓ Colima setup completed successfully"
}