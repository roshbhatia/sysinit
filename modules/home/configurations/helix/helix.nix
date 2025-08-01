{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  helixTheme = themes.getAppTheme "helix" values.theme.colorscheme values.theme.variant;
in
{
  programs.helix = {
    enable = true;
    settings = {
      theme = helixTheme;
      editor = {
        bufferline = "always";
        color-modes = true;
        completion-replace = true;
        cursorline = true;
        gutters = [
          "diagnostics"
          "line-numbers"
          "spacer"
          "diff"
        ];
        idle-timeout = 1;
        line-number = "relative";
        popup-border = "all";
        rainbow-brackets = true;
        rulers = [ 100 ];
        scrolloff = 5;
        true-color = true;
        lsp.display-messages = true;
      };

      editor.file-picker = {
        git-global = true;
        git-ignore = true;
      };

      editor.statusline = {
        center = [ ];
        left = [
          "mode"
          "selections"
          "spinner"
          "file-name"
        ];
        mode-separator = "";
        right = [
          "version-control"
          "workspace-diagnostics"
          "diagnostics"
          "file-encoding"
          "file-line-ending"
          "file-type"
          "position-percentage"
          "position"
          "spacer"
          "total-line-numbers"
        ];
        separator = "";
      };

      editor.soft-wrap = {
        enable = true;
      };
    };
  };
}

