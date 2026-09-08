# The seams between the tools this repository composes. Each one is a value
# one tool prints and another tool must answer to, with no import between them.
{ pkgs, lib }:
let
  inherit (lib) mkOption types;

  skillTools = import ../modules/home/programs/llm/skill-tools.nix { inherit lib pkgs; };

  # gate.nix reads only these four options out of a home-manager evaluation, so
  # the module renders its real document here without a host closure.
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

  # No fromYAML at evaluation time, so read the ignore list off the source.
  dependabotIgnored = map builtins.head (
    builtins.filter (match: match != null) (
      map (builtins.match ''[[:space:]]*-[[:space:]]*dependency-name:[[:space:]]*"([^"]+)".*'') (
        lib.splitString "\n" (builtins.readFile ../.github/dependabot.yml)
      )
    )
  );
  unpinned = builtins.filter (name: !(builtins.elem name dependabotIgnored)) tagPinned;
in
assert lib.assertMsg (
  tagPinned != [ ]
) "no roshbhatia flake input is pinned to a release tag; the lock shape changed";
assert lib.assertMsg (unpinned == [ ])
  "tag-pinned flake inputs missing from the .github/dependabot.yml ignore list, so dependabot can propose a downgrade: ${lib.concatStringsSep ", " unpinned}";
pkgs.runCommand "llm-composition"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.yq-go
    ];
  }
  ''
    yq -o=json '.' ${gateConfig} > config.json

    # A gate decision joins an orc checkpoint only through these two names.
    jq -e '.log_fields.orc_session == "ORC_SESSION_ID"
      and .log_fields.orc_scope == "ORC_SCOPE"' config.json > /dev/null

    # Every provider that denies a whole-file read prints the same sentence, so
    # they must name one reader. read-router and bash-guard both do; a third
    # that forgets the arg falls back to gate's default and disagrees silently.
    readers=$(jq -r '[.chains.PreToolUse[] | select(.args.reader) | .args.reader]
      | unique | .[]' config.json)
    test "$(printf '%s\n' "$readers" | wc -l)" -eq 1
    carriers=$(jq -r '[.chains.PreToolUse[] | select(.args.reader) | .provider]
      | sort | join(" ")' config.json)
    test "$carriers" = "bash-guard read-router"

    reader="$readers"
    template="''${reader##*-t }"
    prompt="${askTemplates}/ask/templates/prompts/$template.yaml"
    test -f "$prompt"

    yq -o=json '.' "$prompt" > prompt.json
    jq -e --arg name "$template" '.name == $name
      and (.provider | type == "string" and length > 0)
      and (.model | type == "string" and length > 0)' prompt.json > /dev/null
    schema=$(jq -r '.schema' prompt.json)
    test -f "${askTemplates}/ask/templates/schemas/$schema.yaml"

    touch "$out"
  ''
