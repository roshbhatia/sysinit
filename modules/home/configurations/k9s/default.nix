{
  ...
}:

{
  stylix.targets.k9s.enable = true;

  programs.k9s = {
    enable = true;
    settings = {
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
          noIcons = true;
          reactive = true;
          defaultsToFullScreen = true;
        };
        noIcons = false;
        skipLatestRevCheck = true;
        keepMissingClusters = false;
        logger = {
          tail = 1000;
          buffer = 100;
          sinceSeconds = 86400;
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
}
