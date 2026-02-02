# Security: SSH, sudo, user account, nix-ld
{
  values,
  pkgs,
  lib,
  config,
  ...
}:

{
  # Sudo
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    extraConfig = ''
      Defaults lecture="never"
    '';
  };

  # SSH hardening
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = false;
      PrintMotd = false;
      AllowUsers = [ values.user.username ];
      AcceptEnv = [
        "TERM_PROGRAM"
        "TERM_PROGRAM_VERSION"
        "WEZTERM_*"
      ];
    };
  };

  # User account
  programs.zsh.enable = true;

  users.users.${values.user.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${values.user.username}";
    group = values.user.username;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ]
    ++ lib.optionals config.programs.gamemode.enable [ "gamemode" ];
    description = values.git.name;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
    ];
  };

  users.groups.${values.user.username} = { };

  # nix-ld for non-Nix binaries
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ stdenv.cc.cc ];
  };
}
