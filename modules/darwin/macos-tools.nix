{
  pkgs,
  config,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    lima # ad-hoc VM manager, driven by hand; nothing auto-starts it
  ];

  home-manager.users.${config.sysinit.user.username} = {
    home.packages = with pkgs; [
      colima
      qemu
      _1password-gui
    ];
  };

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
