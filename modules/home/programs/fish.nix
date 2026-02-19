{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  shell = import ../../lib/shell.nix { inherit lib; };
  paths_lib = import ../../lib/paths.nix { inherit config lib; };

  sharedAliases = shell.aliases;
  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;
in
{
  programs.fish = {
    enable = true;
    shellAliases = mkDefault sharedAliases;

    plugins = [
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }
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

      # Re-render prompt on bind mode change for oh-my-posh
      rerender_on_bind_mode_change = {
        onVariable = "fish_bind_mode";
        body = ''
          if test "$fish_bind_mode" != paste -a "$fish_bind_mode" != "$FISH__BIND_MODE"
            set -gx FISH__BIND_MODE $fish_bind_mode
            if type -q omp_repaint_prompt
              omp_repaint_prompt
            end
          end
        '';
      };

      # Mask default mode prompt to prevent echoing
      fish_default_mode_prompt = {
        description = "Display vi prompt mode";
        body = ''
          # This function is masked and does nothing
        '';
      };
    };

    shellInit = ''
      # Add paths
      ${concatMapStringsSep "\n" (path: "fish_add_path -g ${path}") pathsList}
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
