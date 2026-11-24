{ lib, pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;

    mutableSettings = true;
    globalConfig = {
      plugins.nix = "${pkgs.mise-nix}";

      tool_alias = {
        bun = "nix:bun";
        shellcheck = "nix:shellcheck";
        tflint = "nix:tflint";
        yq = "nix:yq-go";
      };
    };
  };

  programs.nushell.extraEnv = lib.mkBefore ''
    # Nested shells must capture their own PATH before mise generates activation.
    hide-env --ignore-errors __MISE_ORIG_PATH
  '';

  xdg.dataFile."mise/plugins/nix".source = pkgs.mise-nix;
}
