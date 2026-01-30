let
  lsp = builtins.mapAttrs (
    _: cfg:
    let
      cmd =
        if cfg ? command && builtins.isList cfg.command then
          builtins.head cfg.command
        else
          cfg.command or null;
    in
    (removeAttrs cfg [ "extensions" ]) // (if cmd != null then { command = cmd; } else { })
  ) (import ../../shared/lib/lsp-config.nix).lsp;
in
{
  stylix.targets.helix.opacity.enable = false;

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";
        mouse = true;
        auto-save = true;
        bufferline = "multiple";
        true-color = true;
        undercurl = true;
        clipboard-provider = "pasteboard";
        cursorline = false;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "block";
        };

        file-picker = {
          parents = true;
        };

        whitespace = {
          render = {
            space = "none";
            tab = "none";
            newline = "none";
          };
        };

        lsp = {
          display-messages = true;
          auto-signature-help = true;
          display-inlay-hints = true;
          display-signature-help-docs = true;
        };

        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "file-modification-indicator"
          ];
          center = [
            "file-type"
            "read-only-indicator"
            "file-encoding"
          ];
          right = [
            "diagnostics"
            "selections"
            "register"
            "position"
            "file-line-ending"
          ];
          separator = " | ";
          mode = {
            normal = " 󰘧 ";
            insert = "  ";
            select = " 󰈈 ";
          };
        };
      };
    };

    languages = {
      language-server = lsp;
    };
  };
}
