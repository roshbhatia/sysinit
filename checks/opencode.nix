{ pkgs }:
let
  module = import ../modules/home/programs/llm/harnesses/opencode {
    inherit pkgs;
    inherit (pkgs) lib;
    config = { };
  };
  files = builtins.head module.xdg.configFile.contents;
  bridge = pkgs.writeText "opencode-bridge.zsh" files."carapace/bridge/zsh/.zshrc".text.content;
  spec = pkgs.writeText "opencode.yaml" files."carapace/specs/opencode.yaml".text;
  aliasSpec = pkgs.writeText "opencode2.yaml" files."carapace/specs/opencode2.yaml".text;
  render = import ../modules/home/programs/llm/harnesses/opencode/render.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  mainConfig = pkgs.writeText "opencode-main.json" (builtins.toJSON render.main);
  tuiConfig = pkgs.writeText "opencode-cli.json" (builtins.toJSON render.tui);
in
pkgs.runCommand "opencode-v2-plugins"
  {
    nativeBuildInputs = [
      pkgs.bun
      pkgs.carapace
      pkgs.zsh
      pkgs.nushell
      pkgs.opencode
      (pkgs.python3.withPackages (ps: [ ps.jsonschema ]))
    ];
  }
  ''
    python3 - ${render.schemas} ${mainConfig} ${tuiConfig} <<'PY'
    import json
    import pathlib
    import sys

    import jsonschema

    for name, config_path in zip(["config", "cli"], sys.argv[2:], strict=True):
        schema = json.loads((pathlib.Path(sys.argv[1]) / f"{name}.json").read_text())
        config = json.loads(pathlib.Path(config_path).read_text())
        validator = jsonschema.validators.validator_for(schema)(schema)
        validator.validate(config)
        try:
            validator.validate(config | {"sysinit_unknown_key": True})
        except jsonschema.ValidationError:
            pass
        else:
            raise AssertionError(f"{name} schema accepted an unknown root key")
    PY
    export HOME="$TMPDIR/home"
    export OPENCODE_PLUGIN_DIR="$TMPDIR/opencode"
    mkdir -p "$HOME" "$OPENCODE_PLUGIN_DIR/plugins"
    cp ${../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-notify.ts} "$OPENCODE_PLUGIN_DIR/sysinit-notify.ts"
    cp ${../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-process.ts} "$OPENCODE_PLUGIN_DIR/sysinit-process.ts"
    ln -s ../sysinit-process.ts "$OPENCODE_PLUGIN_DIR/plugins/sysinit-process.ts"
    cp ${../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-edits.ts} "$OPENCODE_PLUGIN_DIR/plugins/sysinit-edits.ts"
    cp ${./opencode-plugins.test.js} ./opencode-plugins.test.js
    bun test ./opencode-plugins.test.js
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/carapace/bridge/zsh" "$XDG_CONFIG_HOME/carapace/specs"
    cp ${bridge} "$XDG_CONFIG_HOME/carapace/bridge/zsh/.zshrc"
    cp ${spec} "$XDG_CONFIG_HOME/carapace/specs/opencode.yaml"
    cp ${aliasSpec} "$XDG_CONFIG_HOME/carapace/specs/opencode2.yaml"
    nu --no-config-file -c '
      for cmd in [opencode opencode2] {
        let values = (carapace $cmd nushell $cmd run --sta | from json | get value | str trim)
        if "--standalone" not-in $values { error make {msg: $"Missing v2 completion for ($cmd)"} }
      }
    '
    touch "$out"
  ''
