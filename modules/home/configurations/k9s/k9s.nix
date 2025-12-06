{
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;

  k9sAdapter = themes.adapters.k9s;
  k9sThemeConfig = k9sAdapter.createK9sTheme theme validatedTheme;

  # Use theme name for k9s skin (k9s expects a filename-safe name)
  themeName = "${validatedTheme.colorscheme}-${validatedTheme.variant}";
in
{
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
          skin = themeName;
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

  # Generate k9s skin YAML from semantic colors
  xdg.configFile."k9s/skins/${themeName}.yaml" = {
    text = k9sThemeConfig.themeYaml;
    force = true;
  };
}
