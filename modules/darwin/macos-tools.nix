{ pkgs, config, lib, ... }:

{
  # macOS system-level packages (not home-manager)
  environment.systemPackages = with pkgs; [
    lima # VM manager (system-level for launchd integration)
  ];

  # macOS-specific home packages
  home-manager.users.${config.sysinit.user.username} = {
    home.packages = with pkgs; [
      # VM/Docker infrastructure (macOS only)
      colima
      qemu
      # GUI applications
      _1password-gui
    ];
  };

  launchd.user.agents = {
    colima = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.colima}/bin/colima"
          "start"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/colima.log";
        StandardErrorPath = "/tmp/colima.error.log";
      };
    };
  } // lib.optionalAttrs (config.sysinit.darwin.lima.instanceName != "") {
    "lima-${config.sysinit.darwin.lima.instanceName}" = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.lima}/bin/limactl"
          "start"
          config.sysinit.darwin.lima.instanceName
        ];
        RunAtLoad = true;
      };
    };
  };
}
