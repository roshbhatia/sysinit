{
  lib,
  pkgs,
  platform,
  ...
}:

lib.mkIf platform.isDarwin {
  programs._1password = {
    enable = true;
  };

  programs._1password-gui = {
    enable = true;
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  home.file.".ssh/config".text = lib.mkAfter ''
    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';
}
