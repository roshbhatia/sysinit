{
  pkgs,
  homeManagerLib,
  darwinConfigurations,
  nixosConfigurations,
  ...
}:
let
  inherit (pkgs) lib;

  # Every check that is pure evaluation shares this. The derivation carries no
  # build step; the assertions above it decide whether it evaluates at all.
  evalOnly = name: pkgs.runCommand name { } "touch $out";

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
{
  task-commands = import ./task-commands.nix { inherit pkgs; };
  utility-contracts = import ./utility-contracts.nix { inherit pkgs; };
  firefox = import ./firefox.nix { inherit pkgs darwinConfigurations nixosConfigurations; };
  editor-composition = import ./editor-composition.nix { inherit pkgs homeManagerLib; };
  slack-guard = import ./slack-guard.nix { inherit pkgs; };
  url-routing = pkgs.runCommand "url-routing-test" { nativeBuildInputs = [ pkgs.lua5_4 ]; } ''
    lua ${./url-routing.lua} ${../modules/darwin/home/hammerspoon/lua/sysinit/pkg/url_routing.lua}
    touch "$out"
  '';
  hammerspoon-startup =
    pkgs.runCommand "hammerspoon-startup-test" { nativeBuildInputs = [ pkgs.lua5_4 ]; }
      ''
        lua ${./hammerspoon-startup.lua} ${../modules/darwin/home/hammerspoon/lua/sysinit/pkg/core/startup.lua}
        touch "$out"
      '';
  completion-cache =
    pkgs.runCommand "completion-cache-test"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.zsh
        ];
      }
      ''
        python3 ${./completion-cache.py} ${../modules/home/programs/zsh/core/compinit.zsh}
        touch "$out"
      '';
  generated-format = import ./generated-format.nix { inherit pkgs; };
  agent-sessions = import ./agent-sessions.nix { inherit pkgs; };
  mcp-client-routing = import ./mcp-routing.nix { inherit pkgs; };
  managed-file-cache = import ./managed-file-cache.nix { inherit pkgs; };
  incremental-defaults =
    pkgs.runCommand "incremental-defaults-test" { nativeBuildInputs = [ pkgs.python3 ]; }
      ''
        python3 ${./incremental-defaults.py} ${../modules/darwin/defaults-incremental.py}
        touch "$out"
      '';
  homebrew-reconcile =
    pkgs.runCommand "homebrew-reconcile-test"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.bash
        ];
      }
      ''
        python3 ${./homebrew-reconcile.py} ${../modules/darwin/reconcile-homebrew.sh}
        touch "$out"
      '';
  app-copy-state = pkgs.runCommand "app-copy-state-test" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${./app-copy-state.py} ${../modules/home/app-copy-state.py}
    touch "$out"
  '';
  github-runner-guard = import ./github-runner-guard.nix { inherit pkgs; };
  # These assertions sat at file scope. One failure aborted the whole attrset,
  # so every check on every system reported the same message, and the message
  # named no invariant.
  command-path-order =
    assert lib.assertMsg (
      builtins.elemAt darwinPath 3 == "/opt/homebrew/bin"
    ) "darwin path entry 3 is ${builtins.elemAt darwinPath 3}, not /opt/homebrew/bin";
    assert lib.assertMsg (
      builtins.elemAt darwinPath 4 == "/opt/homebrew/sbin"
    ) "darwin path entry 4 is ${builtins.elemAt darwinPath 4}, not /opt/homebrew/sbin";
    assert lib.assertMsg (
      builtins.elemAt darwinPath 5 == "/usr/local/bin"
    ) "darwin path entry 5 is ${builtins.elemAt darwinPath 5}, not /usr/local/bin";
    assert lib.assertMsg (
      !(builtins.elem "/opt/homebrew/bin" linuxPath)
    ) "the linux path carries /opt/homebrew/bin, which exists only on darwin";
    assert lib.assertMsg (builtins.all (path: builtins.elem path darwinShellPath)
      standardSystemPath
    ) "the darwin shell path drops one of ${builtins.concatStringsSep " " standardSystemPath}";
    assert lib.assertMsg (builtins.all (path: builtins.elem path linuxShellPath)
      standardSystemPath
    ) "the linux shell path drops one of ${builtins.concatStringsSep " " standardSystemPath}";
    evalOnly "command-path-order";

  # Named separately. Folded into command-path-order, an MCP regression
  # reported a path failure.
  mcp-harness-suppression =
    assert lib.assertMsg (
      ampMcpServers.kept.command == "kept"
    ) "the amp MCP set dropped the kept server";
    assert lib.assertMsg (
      !(ampMcpServers ? suppressed)
    ) "the amp MCP set carries suppressed, which harnessSuppressedServers removes";
    evalOnly "mcp-harness-suppression";
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
      evalOnly "cua-computer-server-not-applicable";
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
  # modules/darwin/prune-system-generations.sh is a launchd job, and the test
  # drives nix-env, which creates /nix/var/nix/profiles. The Linux sandbox
  # denies that. macOS builds are unsandboxed, which is the only reason this
  # ever passed there.
  system-generation-prune =
    if pkgs.stdenv.hostPlatform.isDarwin then
      import ./system-generation-prune.nix { inherit pkgs; }
    else
      evalOnly "system-generation-prune-not-applicable";
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
