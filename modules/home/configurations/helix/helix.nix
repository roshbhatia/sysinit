{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  helixTheme = themes.getAppTheme "helix" values.theme.colorscheme values.theme.variant;
in
{
  programs.helix = {
    enable = true;
    settings = {
      theme = helixTheme;

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

        keys = {
          select = {
            "C-d" = "half_page_down";
            "C-u" = "half_page_up";
          };

          normal = {
            "C-d" = "half_page_down";
            "C-u" = "half_page_up";
          };

          insert = {
            "C-d" = "half_page_down";
            "C-u" = "half_page_up";
          };
        };

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
      language-server = {
        rust-analyzer = {
          config = {
            checkOnSave = {
              command = "clippy";
            };
            procMacro = {
              enable = true;
            };
          };
        };

        gopls = {
          command = "gopls";
          config = {
            gofumpt = true;
            staticcheck = true;
            analyses = {
              unusedparams = true;
              nilness = true;
            };
          };
        };

        golangci-lint-ls = {
          command = "golangci-lint-langserver";
          args = [
            "-debug"
            "false"
          ];
        };

        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
          config = {
            python.analysis = {
              typeCheckingMode = "basic";
              autoImportCompletions = true;
            };
          };
        };

        nil = {
          command = "nil";
          config.nil = {
            formatting.command = [ "alejandra" ];
            diagnostics.ignored = [
              "unused_binding"
              "unused_with"
            ];
          };
        };

        typescript-language-server = {
          config = {
            preferences = {
              includeInlayParameterNameHints = "all";
              includeInlayParameterNameHintsWhenArgumentMatchesName = true;
              includeInlayFunctionParameterTypeHints = true;
              includeInlayVariableTypeHints = true;
              includeInlayPropertyDeclarationTypeHints = true;
              includeInlayFunctionLikeReturnTypeHints = true;
            };
          };
        };

        vscode-eslint-language-server = {
          command = "vscode-eslint-language-server";
          args = [ "--stdio" ];
        };

        vscode-json-language-server = {
          command = "vscode-json-language-server";
          args = [ "--stdio" ];
        };

        yaml-language-server = {
          command = "yaml-language-server";
          args = [ "--stdio" ];
          config = {
            yaml = {
              schemas = {
                "https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.{yml,yaml}";
                "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks" =
                  "roles/*/tasks/*.{yml,yaml}";
                "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook" =
                  "*play*.{yml,yaml}";
              };
            };
          };
        };

        ansible-language-server = {
          command = "ansible-language-server";
          args = [ "--stdio" ];
        };

        dockerfile-language-server = {
          command = "docker-langserver";
          args = [ "--stdio" ];
        };

        docker-compose-langserver = {
          command = "docker-compose-langserver";
          args = [ "--stdio" ];
        };

        jdtls = {
          command = "jdtls";
        };

        zls = {
          command = "zls";
        };

        bash-language-server = {
          command = "bash-language-server";
          args = [ "start" ];
        };

        awk-language-server = {
          command = "awk-language-server";
        };

        vscode-css-language-server = {
          command = "vscode-css-language-server";
          args = [ "--stdio" ];
        };

        markdown-oxide = {
          command = "markdown-oxide";
        };

        systemd-lsp = {
          command = "systemd-lsp";
        };

        lua-language-server = {
          command = "lua-language-server";
        };

        terraform-ls = {
          command = "terraform-ls";
          args = [ "serve" ];
        };

        copilot = {
          command = "copilot-language-server";
          args = [ "--stdio" ];
        };

        scls = {
          command = "simple-completion-language-server";
          config = {
            max_completion_items = 100;
            feature_words = false;
            feature_snippets = true;
            snippets_first = true;
            snippets_inline_by_word_tail = false;
            feature_unicode_input = false;
            feature_paths = false;
            feature_citations = false;
          };
        };
      };

      language = [
        {
          name = "nix";
          scope = "source.nix";
          file-types = [ "nix" ];
          auto-format = true;
          formatter.command = "alejandra";
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
          formatter.command = "goimports";
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
            "markdown-oxide"
            "copilot"
          ];
          auto-format = false;
        }
        {
          name = "systemd";
          scope = "source.systemd";
          file-types = [
            "service"
            "socket"
            "timer"
            "target"
            "mount"
            "automount"
            "swap"
            "path"
            "slice"
          ];
          language-servers = [
            "systemd-lsp"
            "copilot"
          ];
          auto-format = true;
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
