{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.hunk.homeManagerModules.default ];

  programs.hunk = {
    enable = true;
    package = pkgs.hunk;
    enableGitIntegration = false;
    enableJujutsuIntegration = false;
    enableClaudeIntegration = false;
    settings = {
      agent_notes = false;
      menu_bar = false;
      watch = true;
      extensions.paths = map (name: "${config.xdg.configHome}/hunk/extensions/${name}") [
        "hunk-commit-log"
        "hunk-viewed"
      ];
      keybindings = {
        "hunk.review.scrollCodeLeft" = [
          "h"
          "left"
          "shift+left"
        ];
        "hunk.review.scrollCodeRight" = [
          "l"
          "right"
          "shift+right"
        ];
        "hunk.review.pageDown" = [
          "ctrl+f"
          "pagedown"
        ];
        "hunk.review.pageUp" = [
          "ctrl+b"
          "pageup"
        ];
        "hunk.history.pageDown" = [
          "ctrl+f"
          "pagedown"
        ];
        "hunk.history.pageUp" = [
          "ctrl+b"
          "pageup"
        ];
        "hunk.review.halfPageDown" = "ctrl+d";
        "hunk.review.halfPageUp" = "ctrl+u";
        "hunk.history.halfPageDown" = "ctrl+d";
        "hunk.history.halfPageUp" = "ctrl+u";
        "hunk-commit-log.next" = "ctrl+n";
        "hunk-commit-log.previous" = "ctrl+p";
        "hunk-commit-log.toggle" = "C";
        "hunk-viewed.search" = "/";
        "hunk-viewed.searchNext" = "n";
        "hunk-viewed.searchPrevious" = "N";
      };
    };
  };

  xdg.configFile = {
    "hunk/extensions/hunk-commit-log".source = inputs.hunk-commit-log;
    "hunk/extensions/hunk-viewed".source = inputs.hunk-viewed;
  };
}
