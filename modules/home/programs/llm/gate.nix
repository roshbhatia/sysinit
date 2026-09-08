# The gate dispatcher: one authoritative hook layer for every harness.
#
# Each harness declares one `gate hook` per event (lib/guards.nix). The chain
# that runs behind it is this file's concern: which providers, in what order,
# with what arguments. The generic providers come from the gate repository; the
# one provider this repository owns, prose-gate, is a manifest here pointing at
# pkgs.sysinit-utils.
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
  defaults = import ./gate-defaults.nix { rulesFile = "${llmLib.guards.rulesFile pkgs}"; };
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
    # gate does not know what these mean. Naming them here is what lets a
    # decision line join an orc checkpoint without either tool importing the
    # other.
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

  # prose-gate speaks provider/v1 through `utils prose-gate serve`, which
  # routes on the event and on args.mode. vale and the style come from the
  # sysinit-utils wrapper, so the manifest names the wrapper.
  proseGateManifest = {
    version = "provider/v1";
    name = "prose-gate";
    description = "Record the style tells of a reply, remind on the next prompt, and note an oversized teammate report";
    command = [ "${pkgs.sysinit-utils}/bin/prose-gate" ];
    actions."gate.decide" = {
      description = "UserPromptSubmit, SessionStart, Stop, PostToolUse on Agent";
      argv = [ "serve" ];
    };
    defaults.timeout = "5s";
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
    ];

    xdg.configFile = providerFiles // {
      "gate/config.yaml".source = yamlFormat.generate "gate-config.yaml" gateConfig;
      "gate/review.yaml".source = yamlFormat.generate "gate-review.yaml" cfg.review;
      "gate/providers/prose-gate.yaml".source =
        yamlFormat.generate "gate-provider-prose-gate.yaml" proseGateManifest;
    };
  };
}
