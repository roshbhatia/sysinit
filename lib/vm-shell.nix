{
  pkgs,
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
      disk ? "8GiB",
      shareDockerFromHost ? false,
    }:
    let
      # Configure port forwarding based on semantic flags
      portForwards =
        if shareDockerFromHost then
          # Docker daemon socket forwarding (Unix socket, no ports needed)
          # Docker Desktop on macOS exposes socket at /var/run/docker.sock
          ""
        else
          # Default: forward all non-privileged ports for development
          ''
            - guestPortRange: [1024, 65535]
              hostPortRange: [1024, 65535]
          '';

      # Configure mounts based on semantic flags
      dockerMounts =
        if shareDockerFromHost then
          ''
            - location: "/var/run/docker.sock"
              writable: true
          ''
        else
          "";
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
      ${dockerMounts}

      env:
        PROJECT_NAME: "${projectName}"

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
      disk ? "8GiB",
      shareDockerFromHost ? false,
    }:
    ''
      _vm_name="${vmName}"
      _project_dir="${projectDir}"
      _lima_dir="$_project_dir/.lima"
      _lima_config="$_lima_dir/config.yaml"

      # Create .lima directory if it doesn't exist
      if [[ ! -d "$_lima_dir" ]]; then
        echo "Creating .lima directory..."
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
        echo "Generating Lima VM configuration..."
        cat > "$_lima_config" <<'EOF'
      ${generateLimaConfig {
        inherit
          projectName
          projectDir
          image
          cpus
          memory
          disk
          shareDockerFromHost
          ;
      }}
      EOF
        # Substitute actual project directory (handle tilde expansion)
        ${pkgs.gnused}/bin/sed -i.bak "s|${projectDir}|$_project_dir|g" "$_lima_config"
        rm "$_lima_config.bak"
      fi

      # Check if VM exists
      if ! (${vmExists vmName}); then
        echo "Creating VM: $_vm_name..."
        ${limactl} start --name="$_vm_name" --tty=false "$_lima_config"
      elif ! (${vmRunning vmName}); then
        echo "Starting VM: $_vm_name..."
        ${limactl} start "$_vm_name"
      else
        echo "VM already running: $_vm_name"
      fi
    '';

  # Enter VM
  enterVM = vmName: _projectName: ''
    _vm_name="${vmName}"

    echo "Connecting to $_vm_name..."

    export SYSINIT_IN_VM=1

    # Check if already in a VM
    if [[ -n "''${SYSINIT_IN_VM:-}" ]]; then
      echo "Already in VM session. Exit first before entering another VM."
      return 1
    fi

    exec ${limactl} shell "$_vm_name"
  '';

  # Stop VM
  stopVM = vmName: ''
    echo "Stopping VM: ${vmName}..."
    ${limactl} stop "${vmName}"
  '';

  # Destroy VM
  destroyVM = vmName: ''
    echo "Destroying VM: ${vmName}..."
    ${limactl} stop "${vmName}" 2>/dev/null || true
    ${limactl} delete "${vmName}"
  '';

  # Get VM status
  vmStatus = vmName: ''
    ${limactl} list | grep -E "(NAME|^${vmName})" || echo "VM not found: ${vmName}"
  '';

  # Shell hook for auto-entry to VM
  autoEnterShellHook =
    {
      vmName,
      projectName,
      projectDir ? "$(pwd)",
      image ? "lima-dev",
      cpus ? 4,
      memory ? "8GiB",
      disk ? "8GiB",
      shareDockerFromHost ? false,
    }:
    ''
      # Prevent nested VM entry
      if [[ -n "''${SYSINIT_IN_VM:-}" ]]; then
        echo "Already in VM. Skipping auto-entry."
        return 0
      fi

      # Disable auto-entry if requested
      if [[ -n "''${SYSINIT_NO_AUTO_VM:-}" ]]; then
        echo "Auto VM entry disabled. Run 'limactl shell ${vmName}' to connect manually."
        return 0
      fi

      # Ensure VM exists and is running
      ${ensureVM {
        inherit
          vmName
          projectName
          projectDir
          image
          cpus
          memory
          disk
          shareDockerFromHost
          ;
      }}

      # Auto-enter VM
      ${enterVM vmName projectName}
    '';

  # VM management packages required by shell
  vmPackages = with pkgs; [
    lima
    jq
  ];

  # Create a complete VM shell (simplest API)
  mkVmShell =
    {
      projectName ? baseNameOf (toString ./.),
      vmName ? "${projectName}-dev",
      baseShell ? null,
      extraPackages ? [ ],
      image ? "lima-dev",
      cpus ? 4,
      memory ? "8GiB",
      disk ? "8GiB",
      shareDockerFromHost ? false,
    }:
    pkgs.mkShell {
      name = "${projectName}-vm-shell";

      buildInputs =
        (if baseShell != null then (baseShell.buildInputs or [ ]) else [ ]) ++ vmPackages ++ extraPackages;

      shellHook = autoEnterShellHook {
        inherit
          vmName
          projectName
          image
          cpus
          memory
          disk
          shareDockerFromHost
          ;
      };
    };
}
