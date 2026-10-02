{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;

    enableMutableConfig = true;
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

  xdg.dataFile."mise/plugins/nix".source = pkgs.mise-nix;
}
