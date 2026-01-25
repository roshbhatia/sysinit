{ pkgs, ... }:

{
  # === Kubectl: K8s CLI ===
  home.file = {
    ".local/bin/k".source = "${pkgs.kubecolor}/bin/kubecolor";
    ".local/bin/kubectl".source = "${pkgs.kubecolor}/bin/kubecolor";

    ".kube/kuberc".text = ''
      apiVersion: kubectl.config.k8s.io/v1beta1
      kind: Preference

      # Suggested defaults from Kubernetes documentation
      defaults:
        # Default to server-side apply
        - command: apply
          options:
            - name: server-side
              default: "true"

        # Default to interactive deletion to prevent accidents
        - command: delete
          options:
            - name: interactive
              default: "true"

      # Useful aliases
      aliases:
        # Get with JSON output for structured data
        - name: getj
          command: get
          options:
            - name: output
              default: json

        # Get with YAML output
        - name: gety
          command: get
          options:
            - name: output
              default: yaml

        # Wide output for more details
        - name: getw
          command: get
          options:
            - name: output
              default: wide
    '';
  };

  # === K9s: K8s TUI ===
  stylix.targets.k9s.enable = true;

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
