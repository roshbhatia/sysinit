{
  pkgs,
  ...
}:

let

  limactl = "${pkgs.lima}/bin/limactl";

  # Detect Docker socket from active context

in
rec {
  # Generate Lima config from parameters
  generateLimaConfig =
    {
      projectName,
      projectDir,
      image ? "lima",
      cpus ? 4,
      memory ? "8GiB",
      disk ? "8GiB",
      shareDockerFromHost ? false,
      dockerSocketPath ? "",
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
        if shareDockerFromHost && dockerSocketPath != "" then
          ''
            - location: "${dockerSocketPath}"
              writable: true
              mountPoint: /var/run/docker.sock
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

      # Detect and cache Docker socket if sharing from host
      DOCKER_SOCKET_PATH=""
      if [[ "${if shareDockerFromHost then "true" else "false"}" == "true" ]]; then
        echo "Detecting Docker socket from active context..."
        DOCKER_SOCKET_PATH=$(${detectDockerSocket})
        CURRENT_CONTEXT=$(docker context show 2>/dev/null || echo "")
        CACHED_CONTEXT=""
        
        if [[ -f "$_lima_dir/.docker-context" ]]; then
          CACHED_CONTEXT=$(cat "$_lima_dir/.docker-context")
        fi
        
        # Regenerate config if context changed
        if [[ -n "$CURRENT_CONTEXT" ]] && [[ "$CURRENT_CONTEXT" != "$CACHED_CONTEXT" ]]; then
          if [[ -n "$CACHED_CONTEXT" ]]; then
            echo "Docker context changed: $CACHED_CONTEXT → $CURRENT_CONTEXT"
            echo "Regenerating VM configuration..."
          else
            echo "Using Docker context: $CURRENT_CONTEXT"
          fi
          rm -f "$_lima_config"
        fi
        
        echo "Docker socket: $DOCKER_SOCKET_PATH"
      fi

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

      # Docker context tracking
      .docker-context
      .docker-socket
      EOF
      fi

      # Save Docker context and socket path if sharing from host
      if [[ "${if shareDockerFromHost then "true" else "false"}" == "true" ]]; then
        echo "$CURRENT_CONTEXT" > "$_lima_dir/.docker-context"
        echo "$DOCKER_SOCKET_PATH" > "$_lima_dir/.docker-socket"
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
        dockerSocketPath = "$DOCKER_SOCKET_PATH";
      }}
      EOF
        # Substitute actual project directory and Docker socket path
        ${pkgs.gnused}/bin/sed -i.bak \
          -e "s|${projectDir}|$_project_dir|g" \
          -e "s|\$DOCKER_SOCKET_PATH|$DOCKER_SOCKET_PATH|g" \
          "$_lima_config"
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
      image ? "lima",
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
