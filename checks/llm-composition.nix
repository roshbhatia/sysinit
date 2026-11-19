{ pkgs, lib }:
let
  inherit (lib) mkOption types;

  skillTools =
    (lib.evalModules {
      modules = [
        ../modules/home/programs/llm/skill-tools.nix
        hostStub
      ];
    }).config;
  customSkillTools =
    (lib.evalModules {
      modules = [
        ../modules/home/programs/llm/skill-tools.nix
        hostStub
        {
          sysinit.ask.settings.evaluation = {
            provider = "custom-evaluator";
            model = "small";
          };
        }
      ];
    }).config;

  hostStub = {
    options = {
      xdg = {
        stateHome = mkOption { type = types.str; };
        configHome = mkOption { type = types.str; };
        configFile = mkOption {
          type = types.attrsOf (types.submodule { options.source = mkOption { type = types.path; }; });
          default = { };
        };
      };
      home.packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
    };
    config = {
      _module.args = { inherit pkgs; };
      xdg.stateHome = "/state";
      xdg.configHome = "/config";
    };
  };
  gateModule = lib.evalModules {
    modules = [
      ../modules/home/programs/llm/gate.nix
      hostStub
    ];
  };
  gateConfig = gateModule.config.xdg.configFile."gate/config.yaml".source;

  askTemplates = pkgs.linkFarm "ask-templates" (
    lib.mapAttrsToList (name: entry: {
      inherit name;
      path = entry.source;
    }) (lib.filterAttrs (name: _: lib.hasPrefix "ask/templates/" name) skillTools.xdg.configFile)
  );

  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  rootInputs = lock.nodes.root.inputs;
  tagPinned = builtins.filter (
    name:
    let
      original = lock.nodes.${rootInputs.${name}}.original or { };
    in
    builtins.isString rootInputs.${name}
    && (original.owner or "") == "roshbhatia"
    && builtins.match "v[0-9].*" (original.ref or "") != null
  ) (builtins.attrNames rootInputs);

  dependabotIgnored = map builtins.head (
    builtins.filter (match: match != null) (
      map (builtins.match ''[[:space:]]*-[[:space:]]*dependency-name:[[:space:]]*"([^"]+)".*'') (
        lib.splitString "\n" (builtins.readFile ../.github/dependabot.yml)
      )
    )
  );
  unpinned = builtins.filter (name: !(builtins.elem name dependabotIgnored)) tagPinned;
in
assert customSkillTools.sysinit.ask.settings.evaluation.provider == "custom-evaluator";
assert customSkillTools.sysinit.ask.settings.evaluation.model == "small";
assert customSkillTools.sysinit.ask.settings.provider == skillTools.sysinit.ask.settings.provider;
assert lib.assertMsg (
  tagPinned != [ ]
) "no roshbhatia flake input is pinned to a release tag; the lock shape changed";
assert lib.assertMsg (unpinned == [ ])
  "tag-pinned flake inputs missing from the .github/dependabot.yml ignore list, so dependabot can propose a downgrade: ${lib.concatStringsSep ", " unpinned}";
(import ./lib.nix { inherit pkgs; }) {
  name = "llm-composition";
  script = "llm-composition.nu";
  arguments = [
    gateConfig
    askTemplates
  ];
  inputs = [
    pkgs.yq-go
    pkgs.ask
  ];
}
