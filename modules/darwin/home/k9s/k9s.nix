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

  k9sPlugins = {
    plugins = {
      "force-argo-app-sync" = {
        shortCut = "Ctrl-F";
        confirm = true;
        description = "Hard Refresh and Sync";
        scopes = [ "applications" ];
        command = "sh";
        background = true;
        args = [
          "-c"
          ''
            kubectl patch $RESOURCE_NAME $NAME \
                      --context $CONTEXT \
                      --namespace $NAMESPACE \
                      --type merge \
                      -p '{"spec":{"operation":{"initiatedBy":{"username":"$USER"},"sync":{"syncStrategy":{"hook":{}}}}},"metadata":{"labels":{"argocd.argoproj.io/refresh":"hard"}}}'
          ''
        ];
      };

      "show-argo-app-sync-status" = {
        shortCut = "Ctrl-L";
        confirm = false;
        description = "Argo CD Application Sync Status";
        scopes = [ "applications" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          ''watch -n .5 "kubectl get applications -n argocd-system $NAME -o json | jq -r '. as \\$app | \"Application Status -- $NAME: \\\$app.status.sync.status)\", \"Resources Status:\", (\"Kind,Name,Status\", (.status.resources[] | [ .kind, .name, .status ] | @csv))' | awk -F, '{if (NR > 2) {for (i=1; i<=NF; i++) {gsub(/^\\\"|\\\"$/, \"\", $i); if (length($i) > 30) $i = substr($i, 1, 27) \"...\"; else while (length($i) < 30) $i = $i \" \"; } OFS=\"\\t\"; print} else {print $0}}'"''
        ];
      };

      "view-resource-in-vscode" = {
        shortCut = "v";
        description = "View resource in VSCode";
        scopes = [ "all" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          "kubectl get $RESOURCE_NAME/$NAME --namespace $NAMESPACE --context $CONTEXT -o yaml | code -"
        ];
      };

      "view-resource-in-neovim" = {
        shortCut = "n";
        description = "View resource in Neovim";
        scopes = [ "all" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          "kubectl get $RESOURCE_NAME/$NAME --namespace $NAMESPACE --context $CONTEXT -o yaml | nvim -"
        ];
      };
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

    "k9s/plugins.yaml" = {
      text = lib.generators.toYAML { } k9sPlugins;
      force = true;
    };

    "k9s/skins/catppuccin.yaml" = {
      source = ./skins/catppuccin.yaml;
      force = true;
    };
  };
}

