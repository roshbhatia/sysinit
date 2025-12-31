{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      _1password-cli
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      _1password
    ];

  programs.ssh = {
    extraConfig = ''
      IdentityAgent ~/.1password/agent.sock
    '';
  };
}
