{
  lib,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
  providers = {
    changes = {
      actions."changes.inspect" = "Show repository changes for the workspace";
      description = "Render structured workspace changes";
      kind = "changes";
      package = pkgs.orc-provider-changes;
      priority = 100;
    };
    harness = {
      actions = {
        "session.attach" = "Build the native harness resume command";
        "session.bind" = "Detect whether the harness session is active";
      };
      description = "Resume sessions through the registered agent harness";
      kind = "harness";
      package = pkgs.orc-provider-harness;
      priority = 100;
    };
    traces = {
      actions = {
        "session.bind" = "Link a session to its trace identity";
        "session.describe" = "Read the session title and goal";
        "session.inspect" = "Show session activity";
      };
      description = "Read agent titles, goals, messages, and tool activity";
      kind = "activity";
      package = pkgs.orc-provider-traces;
      priority = 100;
    };
    wezterm = {
      actions = {
        "session.bind" = "Detect the current WezTerm pane";
        "terminal.open" = "Open a command in a split pane";
      };
      description = "Open provider command plans in a WezTerm pane";
      kind = "display";
      package = pkgs.orc-provider-wezterm;
      priority = 100;
    };
    zmx = {
      actions = {
        "session.bind" = "Detect the current persistent process";
        "session.launch" = "Launch a managed harness in a persistent session";
        "session.persist" = "Wrap a harness command in a persistent session";
      };
      description = "Keep harness processes available when displays close";
      kind = "persistence";
      package = pkgs.orc-provider-zmx;
      priority = 100;
    };
  };
in
{
  config = {
    home.packages = [ pkgs.orc-cli ] ++ lib.mapAttrsToList (_: provider: provider.package) providers;

    xdg.configFile = lib.mapAttrs' (
      name: provider:
      lib.nameValuePair "orc/providers/${name}.yaml" {
        source = yamlFormat.generate "orc-provider-${name}.yaml" {
          inherit name;
          inherit (provider)
            actions
            description
            kind
            priority
            ;
          command = lib.getExe provider.package;
          version = "orc.provider/v1";
        };
      }
    ) providers;
  };
}
