{ }:
let
  lsp = builtins.mapAttrs (
    _: cfg:
    (removeAttrs cfg [ "extensions" ])
    // {
      command =
        if cfg ? command && builtins.isList cfg.command then
          builtins.head cfg.command
        else
          cfg.command or null;
    }
  ) (import ../../../../shared/lib/lsp);
  languages = [
    {
      name = "nix";
      scope = "source.nix";
      file-types = [ "nix" ];
      auto-format = true;
      formatter.command = "nixfmt";
      language-servers = [
        "nil"
        "copilot"
      ];
    }
    {
      name = "rust";
      scope = "source.rust";
      file-types = [ "rs" ];
      auto-format = true;
      language-servers = [
        "rust-analyzer"
        "copilot"
      ];
    }
    {
      name = "go";
      scope = "source.go";
      file-types = [ "go" ];
      language-servers = [
        "gopls"
        "golangci-lint-ls"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "gofmt";
    }
    {
      name = "python";
      scope = "source.python";
      file-types = [
        "py"
        "pyi"
        "pyx"
        "pxd"
      ];
      auto-format = true;
      language-servers = [
        "pylance"
        "copilot"
      ];
      formatter.command = "ruff";
      formatter.args = [
        "format"
        "--line-length"
        "100"
        "-"
      ];
    }
    {
      name = "c";
      scope = "source.c";
      file-types = [ "c" ];
      language-servers = [
        "clangd"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "clang-format";
    }
    {
      name = "cpp";
      scope = "source.cpp";
      file-types = [
        "cc"
        "cpp"
        "cxx"
        "h"
        "hpp"
        "hxx"
      ];
      language-servers = [
        "clangd"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "clang-format";
    }
    {
      name = "javascript";
      scope = "source.js";
      file-types = [
        "js"
        "mjs"
        "cjs"
      ];
      auto-format = true;
      language-servers = [
        "typescript-language-server"
        "vscode-eslint-language-server"
        "copilot"
      ];
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "babel"
      ];
    }
    {
      name = "typescript";
      scope = "source.ts";
      file-types = [ "ts" ];
      auto-format = true;
      language-servers = [
        "typescript-language-server"
        "vscode-eslint-language-server"
        "copilot"
      ];
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "typescript"
      ];
    }
    {
      name = "jsx";
      scope = "source.jsx";
      file-types = [ "jsx" ];
      auto-format = true;
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "babel"
      ];
      language-servers = [
        "typescript-language-server"
        "vscode-eslint-language-server"
        "copilot"
      ];
    }
    {
      name = "tsx";
      scope = "source.tsx";
      file-types = [ "tsx" ];
      auto-format = true;
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "typescript"
      ];
      language-servers = [
        "typescript-language-server"
        "vscode-eslint-language-server"
        "copilot"
      ];
    }
    {
      name = "json";
      scope = "source.json";
      file-types = [
        "json"
        "jsonc"
        "arb"
        "ipynb"
        "geojson"
      ];
      language-servers = [
        "vscode-json-language-server"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "json"
      ];
    }
    {
      name = "yaml";
      scope = "source.yaml";
      file-types = [
        "yml"
        "yaml"
      ];
      language-servers = [
        "yaml-language-server"
        "ansible-language-server"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "yaml"
      ];
    }
    {
      name = "docker-compose";
      scope = "source.yaml.docker-compose";
      file-types = [
        "docker-compose.yml"
        "docker-compose.yaml"
        "compose.yml"
        "compose.yaml"
      ];
      language-servers = [
        "docker-compose-langserver"
        "yaml-language-server"
        "copilot"
      ];
      auto-format = true;
    }
    {
      name = "dockerfile";
      scope = "source.dockerfile";
      file-types = [
        "dockerfile"
        "Dockerfile"
        "Containerfile"
      ];
      language-servers = [
        "dockerfile-language-server"
        "copilot"
      ];
      auto-format = true;
    }
    {
      name = "java";
      scope = "source.java";
      file-types = [ "java" ];
      language-servers = [
        "jdtls"
        "copilot"
      ];
      auto-format = true;
    }
    {
      name = "zig";
      scope = "source.zig";
      file-types = [ "zig" ];
      language-servers = [
        "zls"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "zig";
      formatter.args = [
        "fmt"
        "--stdin"
      ];
    }
    {
      name = "bash";
      scope = "source.bash";
      file-types = [
        "sh"
        "bash"
        "zsh"
        "ksh"
      ];
      language-servers = [
        "bash-language-server"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "shfmt";
      formatter.args = [
        "-i"
        "2"
      ];
    }
    {
      name = "awk";
      scope = "source.awk";
      file-types = [ "awk" ];
      language-servers = [
        "awk-language-server"
        "copilot"
      ];
      auto-format = true;
    }
    {
      name = "scss";
      scope = "source.scss";
      file-types = [ "scss" ];
      language-servers = [
        "vscode-css-language-server"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "scss"
      ];
    }
    {
      name = "css";
      scope = "source.css";
      file-types = [ "css" ];
      language-servers = [
        "vscode-css-language-server"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "prettier";
      formatter.args = [
        "--parser"
        "css"
      ];
    }
    {
      name = "markdown";
      scope = "source.md";
      file-types = [
        "md"
        "markdown"
        "mdx"
      ];
      language-servers = [
        "copilot"
      ];
      auto-format = false;
    }
    {
      name = "lua";
      scope = "source.lua";
      file-types = [ "lua" ];
      language-servers = [
        "lua-language-server"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "stylua";
      formatter.args = [ "-" ];
    }
    {
      name = "terraform";
      scope = "source.terraform";
      file-types = [
        "tf"
        "tfvars"
      ];
      language-servers = [
        "terraform-ls"
        "copilot"
      ];
      auto-format = true;
      formatter.command = "terraform";
      formatter.args = [
        "fmt"
        "-"
      ];
    }
    {
      name = "hcl";
      scope = "source.hcl";
      file-types = [ "hcl" ];
      language-servers = [
        "terraform-ls"
        "copilot"
      ];
      auto-format = true;
    }
    {
      name = "git-commit";
      language-servers = [ "scls" ];
    }
  ];
in
_: {
  stylix.targets.helix = {
    enable = true;
  };

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";
        mouse = false;
        auto-save = true;
        bufferline = "multiple";
        true-color = true;
        undercurl = true;
        clipboard-provider = "pasteboard";
        cursorline = true;

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
          separator = " ";
          mode = {
            normal = "  ";
            insert = " 󰘧 ";
            select = " 󰈈 ";
          };
        };
      };
    };

    languages = {
      language-server = lsp;
      language = languages;
    };
  };
}
