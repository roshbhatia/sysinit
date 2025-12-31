{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    _1password-cli
    _1password-gui
  ];

  programs.ssh = {
    extraConfig = ''
      IdentityAgent ~/.1password/agent.sock
    '';
  };
}
