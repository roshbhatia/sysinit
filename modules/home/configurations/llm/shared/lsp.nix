let
  lspLib = import ../../../../shared/lib/lsp/default.nix;
in
{
  lsp = lspLib.lsp;
}
