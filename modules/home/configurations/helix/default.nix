let
  lsp = import ../../../shared/lib/lsp;
in
_:

{
  stylix.targets.helix = {
    enable = true;
    opacity.enable = false;
  };

  programs.helix = {
    enable = true;
    settings = {

      editor = {
        line-number = "relative";
        mouse = false;
        auto-save = true;
        completion-trigger-len = 2;
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
          hidden = false;
          parents = true;
        };

        whitespace = {
          render = {
            space = "none";
            tab = "none";
            newline = "none";
          };
        };

        indent-guides = {
          render = true;
          character = "│";
          skip-levels = 1;
        };

        gutters = [
          "diff"
          "line-numbers"
          "spacer"
          "diagnostics"
        ];

        soft-wrap = {
          enable = true;
          max-wrap = 25;
          max-indent-retain = 40;
          wrap-indicator = "↪ ";
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
          mode.normal = "  ";
          mode.insert = " 󰘧 ";
          mode.select = " 󰈈 ";
        };
      };
    };

    languages = {
      language-server = lsp;

      language = [
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
          debugger = {
            name = "lldb-dap";
            transport = "stdio";
            command = "lldb-dap";
            templates = [
              {
                name = "binary";
                request = "launch";
                completion = [
                  {
                    name = "binary";
                    completion = "filename";
                  }
                ];
                args = {
                  program = "{0}";
                  initCommands = [ "command script import /usr/local/etc/lldb_dap_rustc_primer.py" ];
                };
              }
              {
                name = "attach";
                request = "attach";
                completion = [
                  {
                    name = "pid";
                    completion = "text";
                    description = "Process ID to attach to";
                  }
                ];
                args = {
                  pid = "{0}";
                };
              }
            ];
          };
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
          debugger = {
            name = "go-debug";
            transport = "tcp";
            command = "dlv";
            args = [
              "dap"
              "--check-go-version=false"
              "--listen=127.0.0.1:{}"
            ];
            port-arg = "--listen=127.0.0.1:{}";
            templates = [
              {
                name = "source";
                request = "launch";
                completion = [
                  {
                    name = "entrypoint";
                    completion = "filename";
                    default = ".";
                  }
                ];
                args = {
                  mode = "debug";
                  program = "{0}";
                };
              }
              {
                name = "test";
                request = "launch";
                completion = [
                  {
                    name = "tests";
                    completion = "directory";
                    default = ".";
                  }
                ];
                args = {
                  mode = "test";
                  program = "{0}";
                };
              }
              {
                name = "attach";
                request = "attach";
                completion = [
                  {
                    name = "pid";
                    completion = "text";
                  }
                ];
                args = {
                  mode = "local";
                  processId = "{0}";
                };
              }
            ];
          };
        }
        {
          name = "python";
          scope = "source.python";
          file-types = [
            "py"
            "pyi"
            "py3"
            "pyw"
            "ptl"
          ];
          language-servers = [
            "pyright"
            "copilot"
          ];
          auto-format = true;
          debugger = {
            name = "debugpy";
            transport = "stdio";
            command = "python";
            args = [
              "-m"
              "debugpy.adapter"
            ];
            templates = [
              {
                name = "source";
                request = "launch";
                completion = [
                  {
                    name = "entrypoint";
                    completion = "filename";
                    default = "main.py";
                  }
                ];
                args = {
                  program = "{0}";
                  console = "integratedTerminal";
                };
              }
              {
                name = "module";
                request = "launch";
                completion = [
                  {
                    name = "module";
                    completion = "text";
                    description = "Python module to run";
                  }
                ];
                args = {
                  module = "{0}";
                };
              }
              {
                name = "attach";
                request = "attach";
                completion = [
                  {
                    name = "pid";
                    completion = "text";
                    description = "Process ID to attach to";
                  }
                ];
                args = {
                  processId = "{0}";
                };
              }
            ];
          };
        }
        {
          name = "typescript";
          scope = "source.ts";
          file-types = [
            "ts"
            "mts"
            "cts"
          ];
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
          name = "javascript";
          scope = "source.js";
          file-types = [
            "js"
            "mjs"
            "cjs"
          ];
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
    };
  };
}
