{ config, pkgs, ... }:
# `config.yaml` is a template, substituted here rather than checked in resolved.
#
# YAML has no way to read the paths manifest at runtime, so seshy is the one
# consumer whose path is resolved at build time. That keeps it a reader of the
# manifest rather than a second producer of the layout, which is what
# `sessionsDir` used to be.
{
  xdg.configFile."seshy/config.yaml".source = pkgs.replaceVars ./config.yaml {
    seshySessions = config.sysinit.paths.resolved.seshySessions;
  };
}
