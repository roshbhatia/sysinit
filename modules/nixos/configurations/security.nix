# Security: SSH, sudo, user account, nix-ld
{
  pkgs,
  lib,
  config,
  ...
}:

{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    extraConfig = ''
      Defaults lecture="never"
    '';
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = false;
      PrintMotd = false;
      AllowUsers = [ config.sysinit.user.username ];
      AcceptEnv = [
        "TERM_PROGRAM"
        "TERM_PROGRAM_VERSION"
        "WEZTERM_*"
      ];
    };
  };

  programs.zsh.enable = true;

  users.users.${config.sysinit.user.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${config.sysinit.user.username}";
    group = config.sysinit.user.username;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ]
    ++ lib.optionals config.programs.gamemode.enable [ "gamemode" ];
    description = config.sysinit.git.name;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
    ];
  };

  users.groups.${config.sysinit.user.username} = { };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ stdenv.cc.cc ];
  };
}
