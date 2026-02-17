{
  pkgs,
  lib,
  ...
}:

let

  limactl = "${pkgs.lima}/bin/limactl";

in
rec {
  # Generate Lima config from parameters
  generateLimaConfig =
    {
      projectName,
      projectDir,
      image ? "lima-dev",
      cpus ? 4,
      memory ? "8GiB",
      disk ? "50GiB",
      ports ? [
        3000
        8080
        5173
      ],
    }:
    let
      portForwards = lib.concatMapStrings (port: ''
        - guestPort: ${toString port}
          hostPort: ${toString port}
      '') ports;
    in
    ''
      vmType: "vz"
      os: "Linux"
      arch: "aarch64"

      cpus: ${toString cpus}
      memory: "${memory}"
      disk: "${disk}"

      images:
        - location: "~/.lima/_images/sysinit-${image}-latest.qcow2"
          arch: "aarch64"

      mounts:
        - location: "~/.ssh"
          writable: false
        - location: "${projectDir}"
          writable: true
          9p:
            securityModel: "none"
            cache: "mmap"

      env:
        PROJECT_NAME: "${projectName}"
        ZELLIJ_SESSION: "${projectName}"

      portForwards:
      ${portForwards}

      ssh:
        localPort: 0
        loadDotSSHPubKeys: true

      provision:
        - mode: system
          script: |
            #!/bin/sh
            set -eux
            echo "Lima VM provisioned for ${projectName}"

      probes:
        - description: "SSH is ready"
          script: |
            #!/bin/bash
            ssh -o ConnectTimeout=3 127.0.0.1 true
    '';

  # Check if VM exists
  vmExists = vmName: ''
    if ${limactl} list --json 2>/dev/null | ${pkgs.jq}/bin/jq -e '.[] | select(.name == "${vmName}")' > /dev/null 2>&1; then
      true
    else
      false
    fi
  '';

  # Check if VM is running
  vmRunning = vmName: ''
    if ${limactl} list --json 2>/dev/null | ${pkgs.jq}/bin/jq -e '.[] | select(.name == "${vmName}" and .status == "Running")' > /dev/null 2>&1; then
      true
    else
      false
    fi
  '';

  # Ensure VM exists and is running
  ensureVM =
    {
      vmName,
      projectName,
      projectDir ? "$(pwd)",
      image ? "lima-dev",
      cpus ? 4,
      memory ? "8GiB",
      disk ? "50GiB",
      ports ? [
        3000
        8080
        5173
      ],
      verbose ? true,
    }:
    ''
      _vm_name="${vmName}"
      _project_dir="${projectDir}"
      _lima_dir="$_project_dir/.lima"
      _lima_config="$_lima_dir/config.yaml"

      # Create .lima directory if it doesn't exist
      if [[ ! -d "$_lima_dir" ]]; then
        ${lib.optionalString verbose ''echo "Creating .lima directory..."''}
        mkdir -p "$_lima_dir"

        # Create .gitignore
        cat > "$_lima_dir/.gitignore" <<'EOF'
      # Lima VM state files
      *.sock
      *.pid
      ha.log
      serial.log
      EOF
      fi

      # Generate Lima config if it doesn't exist
      if [[ ! -f "$_lima_config" ]]; then
        ${lib.optionalString verbose ''echo "Generating Lima VM configuration..."''}
        cat > "$_lima_config" <<'EOF'
      ${generateLimaConfig {
        inherit
          projectName
          projectDir
          image
          cpus
          memory
          disk
          ports
          ;
      }}
      EOF
        # Substitute actual project directory (handle tilde expansion)
        ${pkgs.gnused}/bin/sed -i.bak "s|${projectDir}|$_project_dir|g" "$_lima_config"
        rm "$_lima_config.bak"
      fi

      # Check if VM exists
      if ! (${vmExists vmName}); then
        ${lib.optionalString verbose ''echo "Creating VM: $_vm_name..."''}
        ${limactl} start --name="$_vm_name" --tty=false "$_lima_config"
      elif ! (${vmRunning vmName}); then
        ${lib.optionalString verbose ''echo "Starting VM: $_vm_name..."''}
        ${limactl} start "$_vm_name"
      else
        ${lib.optionalString verbose ''echo "VM already running: $_vm_name"''}
      fi
    '';

  # Enter VM with auto-attach to Zellij
  enterVM = vmName: projectName: verbose: ''
    _vm_name="${vmName}"

    ${lib.optionalString verbose ''echo "Connecting to $_vm_name (Zellij will auto-attach)..."''}

    export ZELLIJ_SESSION="${projectName}"
    export SYSINIT_IN_VM=1

    # Check if already in a VM
    if [[ -n "''${SYSINIT_IN_VM:-}" ]]; then
      echo "Already in VM session. Exit first before entering another VM."
      return 1
    fi

    exec ${limactl} shell "$_vm_name"
  '';

  # Stop VM
  stopVM = vmName: verbose: ''
    ${lib.optionalString verbose ''echo "Stopping VM: ${vmName}..."''}
    ${limactl} stop "${vmName}"
  '';

  # Destroy VM
  destroyVM = vmName: verbose: ''
    ${lib.optionalString verbose ''echo "Destroying VM: ${vmName}..."''}
    ${limactl} stop "${vmName}" 2>/dev/null || true
    ${limactl} delete "${vmName}"
  '';

  # Get VM status
  vmStatus = vmName: ''
    ${limactl} list | grep -E "(NAME|^${vmName})" || echo "VM not found: ${vmName}"
  '';
}
