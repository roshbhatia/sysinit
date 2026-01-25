let
  lspLib = import ../../../shared/lib/lsp-config.nix;
in
{
  inherit (lspLib) lsp;
}
