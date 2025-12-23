{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  lspConfig = (import ../shared/lsp.nix).lsp;

  # Convert LSP config to Crush format
  formatLspForCrush =
    lspCfg:
    builtins.mapAttrs (_name: lsp: {
      command = builtins.head lsp.command;
      enabled = true;
    }) lspCfg;

  # Base configuration with LSP servers
  crushSettings = lib.mkMerge [
    {
      lsp = formatLspForCrush lspConfig;
      options = {
        context_paths = values.llm.crush.contextPaths;
        tui = {
          compact_mode = values.llm.crush.tui.compactMode;
        };
        inherit (values.llm.crush) debug;
      };
    }
    (lib.mkIf (values.llm.crush.providers != { }) { inherit (values.llm.crush) providers; })
  ];

  crushConfig = builtins.toJSON crushSettings;

  # Create writable config file
  crushConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "crush/config.json";
    text = crushConfig;
    force = false;
  };
in
lib.mkIf values.llm.crush.enable {
  # Enable Crush via NUR module
  programs.crush = {
    enable = true;
    settings = crushSettings;
  };

  # Create writable config using home activation
  home.activation = {
    crushConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] crushConfigFile.script;
  };
}
