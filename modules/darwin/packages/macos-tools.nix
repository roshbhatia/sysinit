{ pkgs, config, ... }:

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

      # GUI applications
      _1password-gui

      # Databases (macOS only, Ascalon uses containers)
      postgresql17Packages.pgvector
      postgresql_17
    ];
  };
}
