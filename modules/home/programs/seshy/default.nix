{ config, pkgs, ... }:
# `config.yaml` is a template, substituted here rather than checked in resolved.
{
  xdg.configFile."seshy/config.yaml".source = pkgs.replaceVars ./config.yaml {
    seshySessions = config.sysinit.paths.resolved.seshySessions;
  };
}
