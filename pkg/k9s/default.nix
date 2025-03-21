{ config, lib, pkgs, ... }:

{
  # K9s configuration
  xdg.configFile = {
    "k9s/config.yaml" = {
      text = ''        
        k9s:
          liveViewAutoRefresh: true
          screenDumpDir: /tmp/dumps
          refreshRate: 2
          maxConnRetry: 5
          readOnly: false
          noExitOnCtrlC: false
          ui:
            enableMouse: false
            headless: false
            logoless: false
            crumbsless: false
            noIcons: false
            reactive: true
            skin: monokai
            defaultsToFullScreen: true
          noIcons: false
          skipLatestRevCheck: false
          keepMissingClusters: false
          logger:
            tail: 200
            buffer: 500
            sinceSeconds: 300
            textWrap: true
            showTime: false
          shellPod:
            image: killerAdmin
            namespace: default
            limits:
              cpu: 100m
              memory: 100Mi
            tty: true
      '';
    };
    
    "k9s/aliases.yaml" = {
      text = ''        
        aliases:
          dp: deployments
          sec: v1/secrets
          jo: jobs
          cr: clusterroles
          crb: clusterrolebindings
          ro: roles
          rb: rolebindings
          np: networkpolicies
          # ---
          nrfrt: nrfruntimes
          xnrfrt: xnrfruntimes
          plat: platforms
          app: applications
      '';
    };
    
    "k9s/skins/monokai.yaml" = {
      source = ./skins/monokai.yaml;
    };
  };
}
