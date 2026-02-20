{
  config,
  lib,
  pkgs,
  values ? { },
  ...
}:

with lib;
let
  shell = import ../../lib/shell.nix { inherit lib; };
  paths_lib = import ../../lib/paths.nix { inherit config lib; };

  sharedAliases = shell.aliases;
  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;
  envVars = values.environment or { };
  envScript = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "set -gx ${k} ${lib.escapeShellArg v}") envVars);
in
{
  programs.fish = {
    enable = true;
    shellAliases = mkDefault sharedAliases;

    plugins = [
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
    ]
    ++ optionals pkgs.stdenv.isDarwin [
      {
        name = "macos";
        src = pkgs.fishPlugins.macos.src;
      }
    ];

    functions = {
      fish_greeting = "";

      __wezterm_set_working_directory = {
        onVariable = "PWD";
        body = ''
          if type -q wezterm
            wezterm set-working-directory 2>/dev/null
          end
        '';
      };
    };

    shellInit = ''
      # Source .fishenv for user-specific environment variables
      [ -f "$HOME/.fishenv" ] && source "$HOME/.fishenv"

      # Add paths
      ${concatMapStringsSep "\n" (path: "fish_add_path -g ${path}") pathsList}

      # Environment variables from values
      ${envScript}
    '';

    interactiveShellInit = ''
      # Vi mode
      fish_vi_key_bindings

      # Cursor shapes for vi modes
      set -g fish_cursor_insert line
      set -g fish_cursor_default block
      set -g fish_cursor_replace_one underscore
      set -g fish_cursor_visual block
    '';
  };
}
