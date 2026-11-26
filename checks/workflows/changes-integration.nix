{ pkgs }:
(import ../lib/nushell.nix { inherit pkgs; }) {
  name = "changes-integration-check";
  script = ./changes-integration.nu;
  sources = [ ../lib/process.nu ];
  arguments = [
    pkgs.changes.version
    pkgs.changes-neovim-plugin
    "${pkgs.sysinit-nvim-source}/after/plugin/changes.lua"
  ];
  inputs = [
    pkgs.changes
    pkgs.changes-provider-git-notes
    pkgs.git
    pkgs.neovim
  ];
  environment.CHANGES_PROVIDERS_DIRECTORY = "${pkgs.changes-provider-git-notes}/share/changes/providers";
}
