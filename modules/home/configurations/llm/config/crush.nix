_:
let
  lspConfig = (import ../shared/lsp.nix).lsp;

  formatLspForCrush =
    lspCfg:
    builtins.mapAttrs (_name: lsp: {
      command = builtins.head lsp.command;
      enabled = true;
    }) lspCfg;
in
{
  programs.crush = {
    enable = true;
    settings = {
      lsp = formatLspForCrush lspConfig;
    };
  };
}
