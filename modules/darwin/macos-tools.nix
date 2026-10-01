{
  pkgs,
  config,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    lima
  ];

  home-manager.users.${config.sysinit.user.username} = {
    home.packages = with pkgs; [
      colima
      qemu
      _1password-gui
    ];
  };

}
