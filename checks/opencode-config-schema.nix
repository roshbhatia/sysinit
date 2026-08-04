# Moved verbatim from flake.nix. The expression is unchanged: its derivation path
# is asserted equal to the pre-move baseline in
# openspec/changes/decompose-flake-checks/drv-baseline.json.
{
  pkgs,
  lib,
  inputs,
  system,
  notifyIcons,
  managedFile,
  ...
}:
# The rendered OpenCode config must satisfy the schema the installed
# build ships. Two layers are needed and neither is sufficient alone:
# this one validates the Nix base plus a fixture pushed through the
# same retired-key delete and merge, and the activation script
let
  render = import ../modules/home/programs/llm/harnesses/opencode/render.nix {
    inherit pkgs lib;
  };
  # The check must validate what activation writes, so it renders the
  # same attrset the module writes. `mcp` is the only host-dependent
  # block; an empty object stands in for it.
  mainJson = pkgs.writeText "opencode-base.json" (builtins.toJSON (render.main // { mcp = { }; }));
  tuiJson = pkgs.writeText "opencode-tui.json" (builtins.toJSON render.tui);
in
pkgs.runCommand "opencode-config-schema-check"
  {
    nativeBuildInputs = [
      pkgs.check-jsonschema
      pkgs.jq
    ];
  }
  ''
    schemas=${render.schemas}

    check-jsonschema --schemafile "$schemas/config.json" ${mainJson}
    check-jsonschema --schemafile "$schemas/tui.json" ${tuiJson}

    # A live file carrying retired keys and a stale nested entry must
    # come out clean once the adoption pass runs. Base-only
    # validation cannot see either case.
    #
    # This exercises `render.mergeProgram`, which models the adopt
    # step's `retire` plus `enforce` shape. The reconciler's own
    # three-way program is covered by the `managed-file-merge3`
    # check; neither check alone covers the whole activation path.
    jq -n '{
      theme:"dark",
      keybinds:{leader:"ctrl+b"},
      tui:{scroll_acceleration:{enabled:false}},
      autoupdate:true,
      provider:{ghost:{name:"removed upstream"}}
    }' > live-main.json
    jq -s ${lib.escapeShellArg (render.mergeProgram render.retiredMain)} live-main.json ${mainJson} > merged-main.json
    check-jsonschema --schemafile "$schemas/config.json" merged-main.json

    jq -e 'has("theme") or has("keybinds") or has("tui") | not' merged-main.json > /dev/null \
      || { echo "FAIL: a retired key survived the merge" >&2; exit 1; }
    jq -e '.provider | has("ghost") | not' merged-main.json > /dev/null \
      || { echo "FAIL: a stale nested provider entry survived the merge" >&2; exit 1; }

    jq -n '{theme:"dark"}' > live-tui.json
    jq -s ${lib.escapeShellArg (render.mergeProgram render.retiredTui)} live-tui.json ${tuiJson} > merged-tui.json
    check-jsonschema --schemafile "$schemas/tui.json" merged-tui.json

    echo "OK: opencode base, tui, and both merged fixtures validate" | tee "$out"
  ''
