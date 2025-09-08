{
  lsp = {
    go = {
      command = [ "gopls" ];
      extensions = [ ".go" ];
      env = { GOTOOLCHAIN = "go1.24.5"; };
    };
    typescript = {
      command = [ "typescript-language-server" ];
      args = [ "--stdio" ];
      extensions = [ ".ts" ".tsx" ];
    };
    nix = {
      command = [ "nil" ];
      extensions = [ ".nix" ];
    };
    lua = {
      command = [ "lua-language-server" ];
      args = [ "--stdio" ];
      extensions = [ ".lua" ];
    };
    python = {
      command = [ "pyright-langserver" ];
      args = [ "--stdio" ];
      extensions = [ ".py" ];
    };
    json = {
      command = [ "json-language-server" ];
      args = [ "--stdio" ];
      extensions = [ ".json" ];
    };
    yaml = {
      command = [ "yaml-language-server" ];
      args = [ "--stdio" ];
      extensions = [ ".yaml" ".yml" ];
    };
    dockerfile = {
      command = [ "docker-langserver" ];
      args = [ "--stdio" ];
      extensions = [ "Dockerfile" ];
    };
    terraform = {
      command = [ "terraform-language-server" ];
      args = [ "serve" ];
      extensions = [ ".tf" ".tfvars" ];
    };
    up = {
      command = [ "up" ];
      args = [ "xpls" "serve" ];
      extensions = [ ".yaml" ];
    };
    systemd_lsp = {
      command = [ "systemd-lsp" ];
      extensions = [
        ".service"
        ".socket"
        ".timer"
        ".mount"
        ".target"
        ".path"
        ".slice"
        ".automount"
        ".swap"
        ".link"
        ".netdev"
        ".network"
        ".nspawn"
        ".override"
      ];
    };
  };
}
