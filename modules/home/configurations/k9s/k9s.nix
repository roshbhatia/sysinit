{
  lib,
  ...
}:

let
  k9sConfig = {
    k9s = {
      liveViewAutoRefresh = true;
      screenDumpDir = "/tmp/dumps";
      refreshRate = 2;
      maxConnRetry = 5;
      readOnly = false;
      noExitOnCtrlC = true;
      ui = {
        enableMouse = false;
        headless = false;
        logoless = false;
        crumbsless = false;
        noIcons = false;
        reactive = true;
        skin = "catppuccin";
        defaultsToFullScreen = true;
      };
      noIcons = false;
      skipLatestRevCheck = false;
      keepMissingClusters = false;
      logger = {
        tail = 200;
        buffer = 500;
        sinceSeconds = 300;
        textWrap = true;
        showTime = false;
      };
      shellPod = {
        image = "killerAdmin";
        namespace = "default";
        limits = {
          cpu = "150m";
          memory = "100Mi";
        };
        tty = true;
      };
    };
  };

  k9sAliases = {
    aliases = {
      dp = "deployments";
      sec = "v1/secrets";
      jo = "jobs";
      cr = "clusterroles";
      crb = "clusterrolebindings";
      ro = "roles";
      rb = "rolebindings";
      np = "networkpolicies";
      app = "applications";
    };
  };
in
{
  xdg.configFile = {
    "k9s/config.yaml" = {
      text = lib.generators.toYAML { } k9sConfig;
      force = true;
    };

    "k9s/aliases.yaml" = {
      text = lib.generators.toYAML { } k9sAliases;
      force = true;
    };

    "k9s/skins/catppuccin.yaml" = {
      source = ./skins/catppuccin.yaml;
      force = true;
    };
  };
}
