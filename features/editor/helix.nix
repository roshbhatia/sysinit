{
  lib,
  profile ? "workstation",
  ...
}:

{
  programs.helix = {
    enable = true;
    languages = lib.mkIf (profile != "minimal") {
      language-server = {
        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
        };
        docker-language-server = {
          command = "docker-language-server";
          args = [
            "start"
            "--stdio"
          ];
        };
        tofu-ls = {
          command = "tofu-ls";
          args = [ "serve" ];
        };
      };
      language = [
        {
          name = "nix";
          language-servers = [ "nixd" ];
          formatter.command = "nixfmt";
        }
        {
          name = "python";
          language-servers = [
            "pyright"
            "ruff"
          ];
        }
        {
          name = "go";
          language-servers = [ "gopls" ];
        }
        {
          name = "dockerfile";
          language-servers = [ "docker-language-server" ];
        }
        {
          name = "markdown";
          language-servers = [ "markdown-oxide" ];
        }
        {
          name = "hcl";
          language-servers = [ "tofu-ls" ];
        }
        {
          name = "tfvars";
          language-servers = [ "tofu-ls" ];
        }
      ];
    };
    settings = {
      editor = {
        line-number = "relative";
        mouse = true;
        auto-save = true;
        bufferline = "multiple";
        true-color = true;
        undercurl = true;
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
            normal = " 󰄚 ";
            insert = " 󰓥 ";
            select = " 󱡃 ";
          };
        };
      };
    };
  };
}
