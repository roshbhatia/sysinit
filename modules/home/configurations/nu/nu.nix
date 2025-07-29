{
  ...
}:
{
  programs.carapace.enableNushellIntegration = true;
  programs.nushell = {
    enable = true;
    configFile.source = ./core/config.nu;
    envFile.source = ./core/env.nu;
  };

  xdg.configFile = {
    "nushell/aliases.nu".source = ./core/aliases.nu;
    "nushell/atuin.nu".source = ./core/atuin.nu;
    "nushell/carapace.nu".source = ./core/carapace.nu;
    "nushell/direnv.nu".source = ./core/direnv.nu;
    "nushell/kubectl.nu".source = ./core/kubectl.nu;
    "nushell/macchina.nu".source = ./core/macchina.nu;
    "nushell/omp.nu".source = ./core/omp.nu;
    "nushell/zoxide.nu".source = ./core/zoxide.nu;
  };
}
