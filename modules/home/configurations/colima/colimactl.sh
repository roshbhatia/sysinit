#!/usr/bin/env bash

export COLIMA_HOME="$XDG_CONFIG_HOME/colima"
CA_CERTS_DIR="/usr/local/share/ca-certificates"
DOCKER_CERTS_DIR="$HOME/.docker/certs.d"
OLD_COLIMA_DIR="$HOME/.colima"
COLIMA_CONFIG_DIR="$XDG_CONFIG_HOME/colima"
ZSCALER_CERT_PATH="$HOME/zscaler-certs/zscaler.pem"
DOCKER_DOMAINS=("registry-1.docker.io" "another-domain.example.com")

check_commands() {
    for cmd in colima security openssl sudo gum; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            gum style --foreground red "Required command '$cmd' not found" >&2
            return 1
        fi
    done
}

move_legacy_config() {
    [[ -d "$OLD_COLIMA_DIR" ]] && {
        [[ -d "$COLIMA_CONFIG_DIR" ]] && rm -rf "$COLIMA_CONFIG_DIR"
        mv "$OLD_COLIMA_DIR" "$COLIMA_CONFIG_DIR"
    }
}

delete_colima_instance() {
    if colima status &>/dev/null; then
        gum confirm "Delete existing Colima instance?" && colima delete -f
    fi
}

setup_cert_dirs() {
    rm -rf "$COLIMA_CONFIG_DIR"
    sudo mkdir -p "$CA_CERTS_DIR" "$DOCKER_CERTS_DIR"
}

extract_certificates() {
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
    security find-certificate -a -p /Library/Keychains/System.keychain > "$temp_dir/all_certs.pem"
    local cert_count
    cert_count=$(grep -c "BEGIN CERTIFICATE" "$temp_dir/all_certs.pem" || echo 0)
    [[ "$cert_count" -eq 0 ]] && { gum style --foreground red "No certificates found in system keychain" >&2; return 1; }
    awk '/BEGIN CERTIFICATE/{if (cert) print cert > out; cert=""; n++; out=sprintf("'"$temp_dir"'/cert-%03d.pem", n)} {cert=cert $0 "\n"} END {if (cert) print cert > out}' "$temp_dir/all_certs.pem"
    local processed=0
    for cert_file in "$temp_dir"/cert-*.pem; do
        if openssl x509 -in "$cert_file" -noout 2>/dev/null; then
            local cert_name
            cert_name=$(openssl x509 -noout -subject -in "$cert_file" 2>/dev/null | sed -n 's/.*CN *= *\([^,]*\).*/\1/p' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-zA-Z0-9-._')
            [[ -z "$cert_name" ]] && cert_name="cert-$processed"
            sudo cp "$cert_file" "$CA_CERTS_DIR/${cert_name}.pem"
            sudo openssl x509 -outform der -in "$cert_file" -out "$DOCKER_CERTS_DIR/${cert_name}.crt"
            processed=$((processed + 1))
        fi
    done
}

copy_zscaler_certs() {
    for domain in "${DOCKER_DOMAINS[@]}"; do
        local dest_dir
        dest_dir="${DOCKER_CERTS_DIR}/${domain}"
        mkdir -p "$dest_dir"
        cp "$ZSCALER_CERT_PATH" "$dest_dir/ca.crt"
    done
}

start_colima() {
    gum spin --spinner dot --title "Starting Colima..." -- colima start --cpu 6 --memory 12 --dns 8.8.8.8 --vz-rosetta -V "$CA_CERTS_DIR"
}

update_ca_certificates() {
    gum spin --spinner dot --title "Updating CA certificates..." -- colima ssh -- sudo update-ca-certificates
}

setup_docker_socket() {
    sudo rm -f /var/run/docker.sock
    sudo ln -s "$XDG_CONFIG_HOME/colima/default/docker.sock" /var/run/docker.sock
}

run_all() {
    check_commands
    move_legacy_config
    delete_colima_instance
    setup_cert_dirs
    extract_certificates
    copy_zscaler_certs
    start_colima
    update_ca_certificates
    setup_docker_socket
    gum style --foreground green "Colima setup completed successfully"
}

main_menu() {
    local action
    action=$(gum choose "Run All" "Check Commands" "Move Legacy Config" "Delete Colima Instance" "Setup Cert Dirs" "Extract Certificates" "Copy Zscaler Certs" "Start Colima" "Update CA Certificates" "Setup Docker Socket")
    case "$action" in
        "Run All") run_all ;;
        "Check Commands") check_commands ;;
        "Move Legacy Config") move_legacy_config ;;
        "Delete Colima Instance") delete_colima_instance ;;
        "Setup Cert Dirs") setup_cert_dirs ;;
        "Extract Certificates") extract_certificates ;;
        "Copy Zscaler Certs") copy_zscaler_certs ;;
        "Start Colima") start_colima ;;
        "Update CA Certificates") update_ca_certificates ;;
        "Setup Docker Socket") setup_docker_socket ;;
    esac
}

if [[ -z "$1" ]]; then
    main_menu
else
    case "$1" in
        check) check_commands ;;
        move-config) move_legacy_config ;;
        delete) delete_colima_instance ;;
        setup-dirs) setup_cert_dirs ;;
        extract-certs) extract_certificates ;;
        copy-certs) copy_zscaler_certs ;;
        start) start_colima ;;
        update-certs) update_ca_certificates ;;
        setup-docker) setup_docker_socket ;;
        all) run_all ;;
        *) echo "Usage: $0 {check|move-config|delete|setup-dirs|extract-certs|copy-certs|start|update-certs|setup-docker|all}" ;;
    esac
fi

