let
  # === Helix ===
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
  ) (import ../shared/lib/lsp-config.nix).lsp;
in
{
  # === Helix: Modal editor ===
  stylix.targets.helix = {
    enable = true;
    # Disable stylix opacity - terminal background transparency is sufficient
    opacity.enable = false;
  };

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
            insert = "  ";
            select = " 󰈈 ";
          };
        };
      };
    };

    languages = {
      language-server = lsp;
    };
  };

  # === EditorConfig: Editor config standard ===
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        insert_final_newline = true;
        trim_trailing_whitespace = true;
        indent_style = "space";
        indent_size = 2;
      };

      "*.{js,jsx,ts,tsx,json}" = {
        indent_size = 2;
      };

      "*.{py,rs}" = {
        indent_size = 4;
      };

      "*.go" = {
        indent_style = "tab";
      };

      "*.md" = {
        trim_trailing_whitespace = false;
      };

      "Makefile" = {
        indent_style = "tab";
      };

      "*.nix" = {
        indent_size = 2;
      };
    };
  };
}
