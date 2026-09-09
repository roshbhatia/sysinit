{ pkgs, lib }:
let
  sources = import ../modules/home/programs/wezterm/sources.nix {
    inherit lib pkgs;
    catalogDir = "/state/roster/catalog";
  };
  yamlFormat = pkgs.formats.yaml { };

  # The remote adapter with its network stubbed: ssh answers `sy list --json`
  # for one session, tether's probe succeeds and its plan is the committed
  # arrakis document. Same script text as the shipped adapter, so the frame
  # handling under test is the one the GUI timer runs.
  fakeSsh = pkgs.writeShellScriptBin "ssh" ''
    printf '%s\n' '[{"name":"sysinit","path":"/home/rshnbhatia/sysinit","repoCount":1,"lastModified":"2026-09-08T16:00:00-07:00"}]'
  '';
  fakeTether = pkgs.writeShellScriptBin "tether" ''
    case "$1" in
      probe) exit 0 ;;
      plan) cat ${./fixtures/tether/plan-arrakis.json} ;;
      *) exit 2 ;;
    esac
  '';
  # The same plan with tether's ssh alternative promoted: a local hop, whose
  # pane must not inherit the remote directory.
  localPlan =
    pkgs.runCommand "tether-plan-arrakis-local.json" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        jq '.plan = .alternatives[0].plan | .hop = .alternatives[0].hop | .chosen = {tier: "ssh", rank: 4} | .loses = .alternatives[0].loses' \
          ${./fixtures/tether/plan-arrakis.json} > "$out"
      '';
  fakeTetherLocal = pkgs.writeShellScriptBin "tether" ''
    case "$1" in
      probe) exit 0 ;;
      plan) cat ${localPlan} ;;
      *) exit 2 ;;
    esac
  '';
  stubbedRemote = sources.remoteSeshyProviderWith [
    pkgs.coreutils
    pkgs.jq
    fakeSsh
    fakeTether
  ];
  stubbedRemoteManifest = yamlFormat.generate "roster-provider-remote-seshy-stubbed.yaml" (
    sources.manifestFor "remote-seshy" sources.sources.remote-seshy stubbedRemote
  );

  listFrame = builtins.toJSON {
    version = "provider/v1";
    kind = "request";
    requestId = "check-1";
    capability = "source.list";
  };
in
pkgs.runCommand "roster-sources"
  {
    nativeBuildInputs = [
      pkgs.roster
      pkgs.jq
      pkgs.check-jsonschema
      sources.packages.seshy
      stubbedRemote
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/roster/providers" "$XDG_CONFIG_HOME/seshy" "$XDG_STATE_HOME"

    # The manifests and config as home-manager installs them pass roster's own
    # validation: kind source, source.list present, command resolvable.
    install -m 0644 ${sources.configFile} "$XDG_CONFIG_HOME/roster/config.json"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        path: file: ''install -m 0644 ${file} "$XDG_CONFIG_HOME/${path}"''
      ) sources.manifestSources
    )}
    roster provider validate
    jq -e '
      (.ttl | test("^[0-9]+(ms|s|m|h)$"))
      and ([.sources[].name] == ["seshy", "remote-seshy"])
      and (.sources | all(.enabled == true))
      and ([.sources[].order] == [10, 20])
    ' "$XDG_CONFIG_HOME/roster/config.json" > /dev/null

    # The seshy adapter against a sessions directory holding one session.
    mkdir -p "$TMPDIR/sessions/demo"
    printf 'sessionsDir: %s\n' "$TMPDIR/sessions" > "$XDG_CONFIG_HOME/seshy/config.yaml"
    printf '%s\n' '${listFrame}' | roster-provider-seshy > "$TMPDIR/seshy.frame"
    jq -e --arg cwd "$TMPDIR/sessions/demo" '
      .version == "provider/v1" and .kind == "result" and .requestId == "check-1" and .status == "ok"
      and (.output.version == "roster.catalog/v1")
      and (.output.source == "seshy")
      and (.output.rows | length == 1)
      and (.output.rows[0].id == "seshy:demo")
      and (.output.rows[0].workspace == "demo")
      and (.output.rows[0].cwd == $cwd)
      and (.output.rows[0].spawn.plan.command == [])
      and (.output.rows[0].spawn.plan.cwd == $cwd)
      and (.output.rows[0].spawn.hop.kind == "local")
      and (.output.rows[0].meta.repoCount == 0)
    ' "$TMPDIR/seshy.frame" > /dev/null

    # The remote adapter with ssh and tether stubbed: one group for arrakis,
    # one row whose spawn is tether's plan and hop, verbatim.
    printf '%s\n' '${listFrame}' | roster-provider-remote-seshy ${sources.remoteSeshyConfig} > "$TMPDIR/remote.frame"
    jq -e '
      .status == "ok"
      and (.output.source == "remote-seshy")
      and (.output.groups | length == 1)
      and (.output.groups[0].id == "host:arrakis")
      and (.output.groups[0].ok == true)
      and (.output.groups[0].stale == false)
      and (.output.groups[0].meta.tier == "native-mux")
      and (.output.rows | length == 1)
      and (.output.rows[0].id == "remote-seshy:arrakis:sysinit")
      and (.output.rows[0].workspace == "arrakis:sysinit")
      and (.output.rows[0].host == "arrakis")
      and (.output.rows[0].group == "host:arrakis")
      and (.output.rows[0].cwd == "/home/rshnbhatia/sysinit")
      and (.output.rows[0].spawn.plan.command == ["zmx", "attach", "sysinit"])
      and (.output.rows[0].spawn.plan.cwd == "/home/rshnbhatia/sysinit")
      and (.output.rows[0].spawn.hop.kind == "native")
      and (.output.rows[0].spawn.hop.ref == "ssh:arrakis")
      and (.output.rows[0].meta.tier == "native-mux")
      and (.output.rows[0].meta.loses == ["roaming", "local-echo"])
    ' "$TMPDIR/remote.frame" > /dev/null

    # When tether picks the ssh tier the hop is local: the command carries the
    # host, and the pane keeps no cwd because the remote directory is not here.
    mkdir -p "$TMPDIR/local/bin"
    cp ${fakeSsh}/bin/ssh "$TMPDIR/local/bin/ssh"
    cp ${fakeTetherLocal}/bin/tether "$TMPDIR/local/bin/tether"
    printf '%s\n' '${listFrame}' \
      | PATH="$TMPDIR/local/bin:$PATH" ${pkgs.bash}/bin/bash \
        ${../modules/home/programs/wezterm/scripts/roster-provider-remote-seshy.sh} \
        ${sources.remoteSeshyConfig} > "$TMPDIR/local.frame"
    jq -e '
      .status == "ok"
      and (.output.rows | length == 1)
      and (.output.rows[0].spawn.hop == {kind: "local"})
      and (.output.rows[0].spawn.plan.command == ["ssh", "-t", "arrakis", "--", "zmx", "attach", "sysinit"])
      and (.output.rows[0].spawn.plan.cwd == "")
      and (.output.rows[0].cwd == "/home/rshnbhatia/sysinit")
      and (.output.rows[0].meta.tier == "ssh")
      and (.output.groups[0].meta.tier == "ssh")
    ' "$TMPDIR/local.frame" > /dev/null

    # An unreachable host is a group with ok false and no rows, never a failed
    # source. The stub exits 255 the way ssh does.
    mkdir -p "$TMPDIR/down/bin"
    printf '#!/bin/sh\nexit 255\n' > "$TMPDIR/down/bin/ssh"
    chmod +x "$TMPDIR/down/bin/ssh"
    cp ${fakeTether}/bin/tether "$TMPDIR/down/bin/tether"
    printf '%s\n' '${listFrame}' \
      | PATH="$TMPDIR/down/bin:$PATH" ${pkgs.bash}/bin/bash \
        ${../modules/home/programs/wezterm/scripts/roster-provider-remote-seshy.sh} \
        ${sources.remoteSeshyConfig} > "$TMPDIR/down.frame"
    jq -e '
      .status == "ok"
      and (.output.rows == [])
      and (.output.groups | length == 1)
      and (.output.groups[0].ok == false)
      and (.output.groups[0].reason == "unreachable")
    ' "$TMPDIR/down.frame" > /dev/null

    # End to end through roster: refresh writes both catalogs, each validates
    # against the schema roster ships, list shows the rows, open resolves the
    # remote row to tether's native hop.
    install -m 0644 ${stubbedRemoteManifest} "$XDG_CONFIG_HOME/roster/providers/remote-seshy.yaml"
    export ROSTER_CATALOG_DIR="$TMPDIR/catalog"
    roster refresh
    for source in seshy remote-seshy; do
      test -s "$ROSTER_CATALOG_DIR/$source.json"
      check-jsonschema --schemafile ${pkgs.roster}/share/roster/schema/roster.catalog.v1.schema.json \
        "$ROSTER_CATALOG_DIR/$source.json"
    done
    jq -e '.generated_at | type == "string"' "$ROSTER_CATALOG_DIR/seshy.json" > /dev/null
    test "$(roster list | wc -l)" -eq 2
    roster list | grep -F 'seshy	demo	session'
    roster list | grep -F 'remote-seshy	arrakis:sysinit	session'
    roster open --json remote-seshy:arrakis:sysinit \
      | jq -e '.spawn.hop == {kind: "native", ref: "ssh:arrakis"} and .spawn.plan.command == ["zmx", "attach", "sysinit"]' > /dev/null
    roster open --json seshy:demo | jq -e '.spawn.hop.kind == "local"' > /dev/null
    touch "$out"
  ''
