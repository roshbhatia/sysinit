{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    # Keeps `mise use -g` and `mise settings set` writable; the declared part
    # lands in conf.d/50-home-manager.toml, which mise merges with config.toml.
    enableMutableConfig = true;
    globalConfig = {
      plugins.nix = "${pkgs.mise-nix}";
      # Opt-in per tool. A project mise.toml keeps its own pin; the nix backend
      # resolves that exact version through search.devbox.sh. `yq` in mise is
      # mikefarah's, which nixpkgs names `yq-go`; plain `yq` there is the
      # Python wrapper at 3.x.
      tool_alias = {
        bun = "nix:bun";
        shellcheck = "nix:shellcheck";
        tflint = "nix:tflint";
        yq = "nix:yq-go";
      };
    };
  };

  # mise links a `[plugins]` path once and never follows a changed one, so a
  # package bump would leave the link on a store path the next GC removes.
  xdg.dataFile."mise/plugins/nix".source = pkgs.mise-nix;
}
