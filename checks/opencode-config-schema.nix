{
  pkgs,
  lib,
  ...
}:
let
  render = import ../modules/home/programs/llm/harnesses/opencode/render.nix {
    inherit pkgs lib;
  };
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
