{
  lib,
  values,
  ...
}:

let

  skinName = values.theme.colorscheme;

  k9sConfig = {
    k9s = {
      liveViewAutoRefresh = true;
      screenDumpDir = "/tmp/dumps";
      refreshRate = 1;
      maxConnRetry = 5;
      readOnly = false;
      noExitOnCtrlC = true;
      ui = {
        enableMouse = false;
        headless = false;
        logoless = true;
        crumbsless = false;
        noIcons = false;
        reactive = true;
        skin = skinName;
        defaultsToFullScreen = false;
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
        fullscreen = true;
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
  xdg.configFile = lib.mkMerge [
    {
      "k9s/config.yaml" = {
        text = lib.generators.toYAML { } k9sConfig;
        force = true;
      };

      "k9s/aliases.yaml" = {
        text = lib.generators.toYAML { } k9sAliases;
        force = true;
      };
    }

    (lib.mkIf (values.theme.colorscheme == "catppuccin") {
      "k9s/skins/catppuccin.yaml" = {
        source = ./skins/catppuccin.yaml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "solarized") {
      "k9s/skins/solarized.yaml" = {
        source = ./skins/solarized.yaml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "rose-pine") {
      "k9s/skins/rose-pine.yaml" = {
        source = ./skins/rose-pine.yaml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "gruvbox") {
      "k9s/skins/gruvbox.yaml" = {
        source = ./skins/gruvbox.yaml;
        force = true;
      };
    })
  ];
}
