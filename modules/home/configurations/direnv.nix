{ pkgs, inputs, ... }:

{
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
      package =
        if inputs ? direnv-instant then
          inputs.direnv-instant.packages.${pkgs.system}.default
        else
          pkgs.direnv;

      stdlib = ''
        # VM detection and helpers
        export_function() {
          eval "''${1}() { ''${2} ; }"
        }

        # Detect VM configuration
        vm_detect() {
          if [[ -f .lima/config.yaml ]]; then
            export SYSINIT_VM_ENABLED=1
            export SYSINIT_VM_NAME="$(basename "$PWD")-dev"

            # Add VM helper functions
            export_function vm-shell "${pkgs.lima}/bin/limactl shell \$SYSINIT_VM_NAME"
            export_function vm-stop "${pkgs.lima}/bin/limactl stop \$SYSINIT_VM_NAME"
            export_function vm-status "${pkgs.lima}/bin/limactl list | grep \$SYSINIT_VM_NAME"
          fi
        }

        # Auto-run VM detection on load
        watch_file .lima/config.yaml
      '';
    };
  };
}
