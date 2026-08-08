{
  pkgs,
  config,
  ...
}:

{
  # macOS system-level packages (not home-manager)
  environment.systemPackages = with pkgs; [
    lima # ad-hoc VM manager, driven by hand; nothing auto-starts it
    tinycast # launcher on cmd+space; registers its own login item via SMAppService
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

  # lima stays installed for ad-hoc VMs, driven by hand. Only colima starts at
  # login, because it is the docker backend.
  launchd.user.agents.colima = {
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
}
