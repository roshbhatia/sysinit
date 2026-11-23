{
  config,
  lib,
  pkgs,
  profile ? "workstation",
  ...
}:

let
  paths = import ../../../lib/paths.nix { inherit lib; };
  profilePath = paths.getPathString config.home.username config.home.homeDirectory;
  shell = import ../../../shared/terminal-shell.nix config;
  editor = pkgs.writeShellScript "rex-review-editor" ''
    export PATH=${lib.escapeShellArg profilePath}
    exec ${lib.escapeShellArg "${config.home.profileDirectory}/bin/nvim"} "$@"
  '';
  settings = {
    # Rex can pass a trailing slash in PWD, which Nushell rejects.
    shell = lib.escapeShellArgs (
      [
        "/usr/bin/env"
        "-u"
        "PWD"
        "PATH=${profilePath}"
      ]
      ++ shell
    );
    inherit (config.sysinit.theme) appearance;
    inherit (config.sysinit.theme.font) monospace size symbols;
  };
in
{
  options.sysinit.rex.enable = lib.mkOption {
    type = lib.types.bool;
    default = profile == "workstation";
    description = "Install the Rex macOS preview alongside WezTerm.";
  };

  config = lib.mkIf config.sysinit.rex.enable {
    home.packages = [ pkgs.rex ];
    sysinit.codesign.protectRunningApps = [ "Rex" ];

    xdg.configFile."rex/init.lua".text = ''
      local settings = rex.json.decode(${builtins.toJSON (builtins.toJSON settings)})
      local reviewr = dofile("${pkgs.sysinit-reviewr}/rex/reviewr/init.lua")
      reviewr.setup({ nvim = "${editor}", command = "lua vim.schedule(vim.cmd.ReviewrOpen)" })
      dofile("${./client.lua}")(rex, settings)
    '';
  };
}
