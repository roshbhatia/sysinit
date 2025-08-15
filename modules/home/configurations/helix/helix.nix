{
  lib,
  values,
  pkgs,
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
        mouse = true;
        middle-click-paste = true;
        auto-save = true;
        auto-format = true;
        auto-completion = true;
        completion-trigger-len = 2;
        completion-replace = true;
        preview-completion-insert = true;
        color-modes = true;
        bufferline = "multiple";
        true-color = true;
        undercurl = true;
        clipboard-provider = "pasteboard";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
          follow-symlinks = true;
          deduplicate-links = true;
          parents = true;
          ignore = true;
          git-ignore = true;
          git-global = true;
          git-exclude = true;
          max-depth = 20;
        };

        search = {
          smart-case = true;
          wrap-around = true;
        };

        whitespace = {
          render = {
            space = "all";
            tab = "all";
            newline = "none";
          };
          characters = {
            space = "·";
            nbsp = "⍽";
            tab = "→";
            newline = "⏎";
            tabpad = "·";
          };
        };

        indent-guides = {
          render = true;
          character = "┊";
          skip-levels = 1;
        };

        gutters = [
          "diff"
          "diagnostics"
          "line-numbers"
          "spacer"
        ];

        soft-wrap = {
          enable = true;
          max-wrap = 25;
          max-indent-retain = 40;
          wrap-indicator = "↪ ";
        };

        lsp = {
          enable = true;
          display-messages = true;
          auto-signature-help = true;
          display-inlay-hints = true;
          display-signature-help-docs = true;
          snippets = true;
          goto-reference-include-declaration = true;
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
          separator = "│";
          mode.normal = "NORMAL";
          mode.insert = "INSERT";
          mode.select = "SELECT";
        };
      };
    };

    # Language-specific configuration
    languages = {
      language-server = {
        # Core languages we use (matching neovim config)
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
          };
        };

        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
        };

        lua-language-server = {
          command = "lua-language-server";
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

        # JavaScript/TypeScript
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

        # Config/Data
        vscode-json-language-server = {
          command = "vscode-json-language-server";
          args = [ "--stdio" ];
        };

        yaml-language-server = {
          command = "yaml-language-server";
          args = [ "--stdio" ];
        };

        # DevOps/Infrastructure
        terraform-ls = {
          command = "terraform-ls";
          args = [ "serve" ];
        };

        tflint = {
          command = "tflint";
          args = [ "--langserver" ];
        };

        dockerfile-language-server = {
          command = "docker-langserver";
          args = [ "--stdio" ];
        };

        helm-ls = {
          command = "helm_ls";
          args = [ "serve" ];
        };

        # Utilities
        jq-lsp = {
          command = "jq-lsp";
        };

        nushell = {
          command = "nu";
          args = [ "--lsp" ];
        };

        # AI Assistant
        copilot = {
          command = "copilot-language-server";
          args = [ "--stdio" ];
        };
      };

      language = [
        # Core languages (matching neovim config)
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
                name = "binary (codelldb)";
                request = "launch";
                completion = [
                  {
                    name = "binary";
                    completion = "filename";
                  }
                ];
                args = {
                  program = "{0}";
                  runInTerminal = true;
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
              "--log"
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
                name = "binary";
                request = "launch";
                completion = [
                  {
                    name = "binary";
                    completion = "filename";
                  }
                ];
                args = {
                  mode = "exec";
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
                    completion = "pid";
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
            ];
          };
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
          language-servers = [
            "typescript-language-server"
            "vscode-eslint-language-server"
            "copilot"
          ];
          debugger = {
            name = "node-debug2";
            transport = "stdio";
            quirks = {
              absolute-paths = true;
            };
            command = "node";
            args = [
              "/path/to/vscode-node-debug2/out/src/nodeDebug.js"
            ];
            templates = [
              {
                name = "source";
                request = "launch";
                completion = [
                  {
                    name = "main";
                    completion = "filename";
                    default = "index.ts";
                  }
                ];
                args = {
                  program = "{0}";
                  cwd = ".";
                  runtimeExecutable = "node";
                  runtimeArgs = [
                    "-r"
                    "ts-node/register"
                  ];
                };
              }
            ];
          };
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
        }
        {
          name = "jsx";
          scope = "source.jsx";
          file-types = [ "jsx" ];
          auto-format = true;
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
            "copilot"
          ];
          auto-format = true;
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
            "tflint"
            "copilot"
          ];
          auto-format = true;
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
          name = "nushell";
          scope = "source.nu";
          file-types = [ "nu" ];
          language-servers = [
            "nushell"
            "copilot"
          ];
          auto-format = true;
        }
      ];
    };
  };

  # Ensure clipboard utilities are available
  home.packages = with pkgs; [
    wl-clipboard # Wayland clipboard
    xclip # X11 clipboard fallback
  ];
}
