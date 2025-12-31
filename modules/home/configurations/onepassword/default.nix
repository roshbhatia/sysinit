{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    _1password-cli
  ];

  programs.ssh = {
    extraConfig = ''
      IdentityAgent ~/.1password/agent.sock
    '';
  };
}
