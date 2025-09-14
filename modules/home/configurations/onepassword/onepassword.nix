{
  lib,
  pkgs,
  ...
}:

lib.mkIf pkgs.stdenv.isDarwin {
  # 1Password SSH agent configuration for macOS
  home.sessionVariables = {
    SSH_AUTH_SOCK = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # Configure SSH to use 1Password agent
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };

  # 1Password CLI packages (if needed)
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.isDarwin [
      _1password
      _1password-gui
    ];
}
