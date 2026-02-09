let
  lsp = {
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
      config = {
        gofumpt = true;
        staticcheck = true;
        analyses = {
          unusedparams = true;
          nilness = true;
        };
      };
      extensions = [ ".go" ];
      env = {
        GOTOOLCHAIN = "go1.24.5";
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
      extensions = [ ".py" ];
    };

    nil = {
      command = "nil";
      config.nil = {
        formatting.command = [ "nixfmt" ];
        diagnostics.ignored = [
          "unused_binding"
          "unused_with"
        ];
      };
      extensions = [ ".nix" ];
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
      extensions = [
        ".ts"
        ".tsx"
      ];
    };

    vscode-eslint-language-server = {
      command = "vscode-eslint-language-server";
      args = [ "--stdio" ];
    };

    vscode-json-language-server = {
      command = "vscode-json-language-server";
      args = [ "--stdio" ];
      extensions = [ ".json" ];
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
      extensions = [
        ".yaml"
        ".yml"
      ];
    };

    ansible-language-server = {
      command = "ansible-language-server";
      args = [ "--stdio" ];
    };

    dockerfile-language-server = {
      command = "docker-langserver";
      args = [ "--stdio" ];
      extensions = [ "Dockerfile" ];
    };

    docker-compose-langserver = {
      command = "docker-compose-langserver";
      args = [ "--stdio" ];
    };

    jdtls = {
      command = "jdtls";
      extensions = [ ".java" ];
    };

    bash-language-server = {
      command = "bash-language-server";
      args = [ "start" ];
      extensions = [
        ".sh"
        ".bash"
        ".zsh"
        ".ksh"
      ];
    };

    awk-language-server = {
      command = "awk-language-server";
      extensions = [ ".awk" ];
    };

    vscode-css-language-server = {
      command = "vscode-css-language-server";
      args = [ "--stdio" ];
      extensions = [
        ".css"
        ".scss"
      ];
    };

    lua-language-server = {
      command = "lua-language-server";
      extensions = [ ".lua" ];
    };

    terraform-ls = {
      command = "terraform-ls";
      args = [ "serve" ];
      extensions = [
        ".tf"
        ".tfvars"
      ];
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

    ast-grep = {
      command = "ast-grep";
      args = [ "lsp" ];
      extensions = [
        ".c"
        ".cpp"
        ".css"
        ".go"
        ".nix"
        ".py"
        ".rs"
        ".sh"
        ".tmpl"
        ".ts"
        ".yaml"
        ".yml"
        ".zsh"
      ];
    };

    nu = {
      command = "nu";
      args = [ "--lsp" ];
      extensions = [ ".nu" ];
    };

    up = {
      command = "up";
      args = [
        "xpls"
        "serve"
      ];
      extensions = [ ".yaml" ];
    };
  };

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
{
  inherit lsp languages;
}
