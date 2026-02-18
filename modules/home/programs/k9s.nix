_:

{
  programs.k9s = {
    enable = true;

    aliases = {
      app = "applications";
      cr = "clusterroles";
      crb = "clusterrolebindings";
      dp = "deployments";
      jo = "jobs";
      np = "networkpolicies";
      rb = "rolebindings";
      ro = "roles";
      sec = "v1/secrets";
    };

    settings.k9s = {
      # General settings
      liveViewAutoRefresh = true;
      maxConnRetry = 5;
      noExitOnCtrlC = true;
      readOnly = false;
      refreshRate = 1;
      screenDumpDir = "/tmp/dumps";
      skipLatestRevCheck = true;
      keepMissingClusters = false;

      # UI settings
      noIcons = false;
      ui = {
        crumbsless = false;
        defaultsToFullScreen = true;
        enableMouse = false;
        headless = false;
        logoless = true;
        noIcons = true;
        reactive = true;
      };

      # Logger settings
      logger = {
        buffer = 100;
        fullscreen = true;
        showTime = false;
        sinceSeconds = 86400;
        tail = 1000;
        textWrap = true;
      };

      # Shell pod settings
      shellPod = {
        image = "killerAdmin";
        namespace = "default";
        tty = true;
        limits = {
          cpu = "150m";
          memory = "100Mi";
        };
      };
    };
  };
}
