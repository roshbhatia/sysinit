{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.sysinit.llm.gate;
  llmLib = import ./lib { inherit lib; };
  defaults = import ./gate-defaults.nix {
    rulesFile = "${llmLib.guards.rulesFile pkgs}";
    styleFile = "${pkgs.vale-styles}/vale.ini";
  };
  yamlFormat = pkgs.formats.yaml { };

  stepType = types.submodule {
    options = {
      provider = mkOption {
        type = types.str;
        description = "A manifest name in ~/.config/gate/providers.";
      };
      match = mkOption {
        type = types.str;
        default = "";
        description = "Regular expression over the tool name; empty matches every event of the chain.";
      };
      args = mkOption {
        type = types.attrs;
        default = { };
        description = "Handed to the provider unchanged.";
      };
      timeout = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Go duration bounding this step; null inherits the provider's default.";
      };
    };
  };

  renderStep =
    step:
    {
      inherit (step) provider;
    }
    // lib.optionalAttrs (step.match != "") { inherit (step) match; }
    // lib.optionalAttrs (step.args != { }) { inherit (step) args; }
    // lib.optionalAttrs (step.timeout != null) { inherit (step) timeout; };

  gateConfig = {
    version = "gate.config/v1";
    log = "${config.xdg.stateHome}/gate/decisions.jsonl";

    log_fields = {
      orc_session = "ORC_SESSION_ID";
      orc_scope = "ORC_SCOPE";
    };
    providers.directory = "${config.xdg.configHome}/gate/providers";
    defaults = {
      timeout = "2s";
      on_rewrite_unsupported = "deny";
    };
    chains = lib.mapAttrs (_event: steps: map renderStep steps) cfg.chains;
  };

  gitAiGateManifest = {
    version = "provider/v1";
    name = "git-ai-gate";
    description = "Record native edit and shell checkpoints for Git AI attribution";
    command = [ "${pkgs.git-ai-gate}/bin/git-ai-gate" ];
    actions."gate.decide" = {
      description = "PreToolUse and PostToolUse edit and shell checkpoints";
      argv = [ "serve" ];
    };
    defaults.timeout = "10s";
  };

  providerFiles = lib.listToAttrs (
    map (name: {
      name = "gate/providers/${name}.yaml";
      value.source = "${pkgs.gate-providers}/share/gate/providers/${name}.yaml";
    }) defaults.providerNames
  );
in
{
  options.sysinit.llm.gate = {
    chains = mkOption {
      type = types.attrsOf (types.listOf stepType);
      default = defaults.chains;
      description = ''
        The provider chain per hook event. The first deny or block wins, a
        rewrite feeds the next provider, every context note reaches the model.
      '';
    };
    review = mkOption {
      type = types.attrs;
      default = defaults.review;
      description = "The review policy: tiers by diff size, sensitive paths, read-only agent types, and the pass cap.";
    };
  };

  config = {
    home.packages = [
      pkgs.gate-cli
      pkgs.gate-providers
      pkgs.agent-notes
    ];

    xdg.configFile = providerFiles // {
      "gate/config.yaml".source = yamlFormat.generate "gate-config.yaml" gateConfig;
      "gate/review.yaml".source = yamlFormat.generate "gate-review.yaml" cfg.review;
      "gate/providers/git-ai-gate.yaml".source =
        yamlFormat.generate "gate-provider-git-ai-gate.yaml" gitAiGateManifest;
    };
  };
}
