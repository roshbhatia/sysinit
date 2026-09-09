{
  pkgs,
  homeManagerLib,
  darwinConfigurations,
  nixosConfigurations,
  ...
}:
let
  commandPath = import ../modules/shared/command-path.nix { inherit (pkgs) lib; };
  darwinPath = commandPath.entriesFor true "/profile/bin";
  linuxPath = commandPath.entriesFor false "/profile/bin";
  shellPaths = import ../modules/lib/paths.nix { inherit (pkgs) lib; };
  darwinShellPath = shellPaths.getAllPaths "roshan" "/Users/roshan";
  linuxShellPath = shellPaths.getAllPaths "roshan" "/home/roshan";
  standardSystemPath = [
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  mcpCatalog = import ../modules/home/programs/llm/lib/mcp-catalog.nix {
    inherit (pkgs) lib;
    additionalServers = {
      kept = {
        command = "kept";
        args = [ ];
      };
      suppressed = {
        command = "suppressed";
        args = [ ];
      };
    };
    harnessSuppressedServers.amp = [ "suppressed" ];
  };
  mcp = import ../modules/home/programs/llm/lib/mcp.nix { inherit (pkgs) lib; };
  ampMcpServers = mcp.formatForAmp (mcpCatalog.serversFor "amp");
  nuFunctions = pkgs.writeText "sysinit-functions.nu" (
    builtins.replaceStrings
      [
        "@seshySessions@"
        "@timeout@"
      ]
      [
        "/tmp/seshy-sessions"
        "${pkgs.coreutils}/bin/timeout"
      ]
      (builtins.readFile ../modules/home/programs/nushell/functions.nu)
  );
in
assert builtins.elemAt darwinPath 3 == "/opt/homebrew/bin";
assert builtins.elemAt darwinPath 4 == "/opt/homebrew/sbin";
assert builtins.elemAt darwinPath 5 == "/usr/local/bin";
assert !(builtins.elem "/opt/homebrew/bin" linuxPath);
assert builtins.all (path: builtins.elem path darwinShellPath) standardSystemPath;
assert builtins.all (path: builtins.elem path linuxShellPath) standardSystemPath;
assert ampMcpServers.kept.command == "kept";
assert !(ampMcpServers ? suppressed);
{
  command-path-order = pkgs.runCommand "command-path-order" { } ''
    touch $out
  '';
  editor-config = import ./editor-config.nix { inherit pkgs; };
  harness-instructions = import ./harness-instructions.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  codex-legacy-hooks = import ./codex-legacy-hooks.nix {
    inherit pkgs homeManagerLib;
    inherit (pkgs) lib;
  };
  closed-lid-ssh = import ./closed-lid-ssh.nix { inherit pkgs; };
  host-access-security = import ./host-access-security.nix {
    inherit
      pkgs
      darwinConfigurations
      nixosConfigurations
      ;
  };
  changes-integration = import ./changes-integration.nix { inherit pkgs; };
  cloud-files = import ./cloud-files.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  cua-computer-server =
    if pkgs.stdenv.hostPlatform.isLinux then
      import ./cua-computer-server.nix {
        inherit pkgs;
        inherit (pkgs) lib;
      }
    else
      pkgs.runCommand "cua-computer-server-not-applicable" { } ''
        touch $out
      '';
  go-tests = pkgs.sysinit-gotools;
  gate-config = import ./gate-config.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  llm-composition = import ./llm-composition.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  orc-no-startup-units = pkgs.runCommand "orc-no-startup-units" { } ''
    test ! -e ${pkgs.orc-cli}/etc/systemd
    test ! -e ${pkgs.orc-cli}/lib/systemd
    test ! -e ${pkgs.orc-cli}/Library/LaunchAgents
    test ! -e ${pkgs.orc-cli}/Library/LaunchDaemons
    touch $out
  '';
  nushell-managed-tools = import ./nushell-managed-tools.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  system-generation-prune = import ./system-generation-prune.nix { inherit pkgs; };
  nushell-command-surface =
    pkgs.runCommand "nushell-command-surface" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        export HOME="$TMPDIR"
        ${pkgs.nushell}/bin/nu --no-config-file -c \
          'use ${nuFunctions} *; ls | columns | to json -r' \
          | jq -e 'index("icon") != null' > /dev/null
        touch $out
      '';
}
