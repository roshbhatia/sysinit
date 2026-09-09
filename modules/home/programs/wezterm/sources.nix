# The one list of roster session sources. It renders ~/.config/roster/config.json
# and one provider/v1 manifest per source, and it builds the two interim
# sources: seshy's own manifest, and an adapter for remote hosts.
#
# A plain function, not a module, so checks/roster-sources.nix can render the
# same manifests and drive the same adapters with the hop tools stubbed.
# wezterm/default.nix installs what this returns.
{
  lib,
  pkgs,
  # The catalog directory roster writes; paths-layout.json's rosterCatalog.
  catalogDir,
}:
let
  remoteHosts = import ./remote-hosts.nix { inherit lib; };
  yamlFormat = pkgs.formats.yaml { };

  # The inner argv a remote session is entered with. The session name is
  # appended. tether wraps it, never composes it.
  remoteAttach = [
    "zmx"
    "attach"
  ];

  # tether shells out to ssh, mosh, tailscale, and wezterm, and its probe
  # records what is on ITS path as the local capability set. The GUI's own PATH
  # is whatever launchd handed the .app, so the hop tools are baked in here or
  # every row degrades to ssh. `timeout` is coreutils; macOS ships none.
  remoteSeshyTools = [
    pkgs.coreutils
    pkgs.jq
    pkgs.openssh
    pkgs.tether
    pkgs.mosh
    pkgs.tailscale
    pkgs.wezterm
  ];

  remoteSeshyConfig = pkgs.writeText "roster-remote-seshy.json" (
    builtins.toJSON {
      hosts = builtins.attrNames remoteHosts.hosts;
      attach = remoteAttach;
    }
  );

  # `tools` is the hop tool set, a parameter so a check can swap in a fake ssh
  # and a fake tether without changing the script.
  remoteSeshyProviderWith =
    tools:
    pkgs.writeShellApplication {
      name = "roster-provider-remote-seshy";
      runtimeInputs = tools;
      text = builtins.readFile ./scripts/roster-provider-remote-seshy.sh;
    };

  remoteSeshyProvider = remoteSeshyProviderWith remoteSeshyTools;

  # The command is an absolute store path, as gate.nix does for git-ai-gate:
  # roster resolves a bare name on the caller's PATH, and the GUI timer's PATH
  # has no profile bin on it.
  manifestFor = name: source: package: {
    version = "provider/v1";
    kind = "source";
    inherit name;
    inherit (source) description;
    command = [ "${package}/bin/${package.meta.mainProgram or package.name}" ] ++ source.commandArgs;
    defaults.timeout = source.timeout;
    actions = {
      "provider.validate".description = "Report that the adapter is present";
      "source.list".description = source.listDescription;
    };
  };

  sources = {
    seshy = {
      # seshy ships its own provider/v1 manifest; only the command is pinned to
      # the store path, since the GUI timer's PATH has no profile bin.
      shipped = "${pkgs.seshy}/share/seshy/providers/seshy.yaml";
      command = [
        "${pkgs.seshy}/bin/sy"
        "provider"
      ];
      order = 10;
      ttl = "10s";
    };
    remote-seshy = {
      description = "seshy sessions on every tether host, one group per host";
      listDescription = "Probe each host, list its sessions, copy tether's plan into each row";
      package = remoteSeshyProvider;
      commandArgs = [ "${remoteSeshyConfig}" ];
      timeout = "30s";
      order = 20;
      ttl = "30s";
    };
  };

  # A source either ships its manifest (seshy) or is an adapter rendered here.
  # A shipped manifest keeps every field the tool wrote; only `command` moves
  # to the pinned store path.
  pinShipped =
    name: source:
    pkgs.runCommand "roster-provider-${name}.yaml" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
      yq '.command = ${builtins.toJSON source.command}' ${source.shipped} > $out
    '';
  manifests = lib.mapAttrs (
    name: source: if source ? shipped then null else manifestFor name source source.package
  ) sources;

  config = {
    ttl = "30s";
    sources = map (name: {
      inherit name;
      enabled = true;
      inherit (sources.${name}) order ttl;
    }) (lib.sort (a: b: sources.${a}.order < sources.${b}.order) (builtins.attrNames sources));
  };

  # Keyed by the xdg.configFile path. `manifestSources` is the rendered YAML,
  # for a check that copies it; `manifestFiles` is the xdg.configFile entry.
  manifestSources = lib.mapAttrs' (
    name: source:
    lib.nameValuePair "roster/providers/${name}.yaml" (
      if source ? shipped then
        pinShipped name source
      else
        yamlFormat.generate "roster-provider-${name}.yaml" manifests.${name}
    )
  ) sources;
  manifestFiles = lib.mapAttrs (_path: source: { inherit source; }) manifestSources;

  # What the wezterm status tick spawns. The GUI's environment has neither the
  # profile bin nor the state layout, so both are pinned here.
  refresh = pkgs.writeShellApplication {
    name = "wezterm-roster-refresh";
    runtimeInputs = [ pkgs.roster ];
    text = ''
      export ROSTER_CATALOG_DIR=${lib.escapeShellArg catalogDir}
      exec roster refresh --if-stale "$@"
    '';
  };

  # What the session tree runs for a row whose spawn is deferred: the row as
  # JSON, plan resolved by the owning source. Same pinning as the refresh.
  open = pkgs.writeShellApplication {
    name = "wezterm-roster-open";
    runtimeInputs = [ pkgs.roster ];
    text = ''
      export ROSTER_CATALOG_DIR=${lib.escapeShellArg catalogDir}
      exec roster open --json "$@"
    '';
  };
in
{
  inherit
    sources
    manifests
    manifestFor
    manifestSources
    manifestFiles
    config
    remoteAttach
    remoteSeshyConfig
    remoteSeshyProviderWith
    refresh
    open
    ;
  packages = {
    remote-seshy = remoteSeshyProvider;
  };
  configFile = pkgs.writeText "roster-config.json" (builtins.toJSON config);
}
