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
    };
  };

  # mise links a `[plugins]` path once and never follows a changed one, so a
  # package bump would leave the link on a store path the next GC removes.
  xdg.dataFile."mise/plugins/nix".source = pkgs.mise-nix;
}
