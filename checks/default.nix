{
  pkgs,
  homeManagerLib,
  homeConfigurations,
  darwinConfigurations,
  nixosConfigurations,
  ...
}:
let
  inherit (pkgs) lib;

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
  pi = pkgs.pi-coding-agent;
  conductor = pkgs.conductor-cli;
  opentelemetry-collector = pkgs.opentelemetry-collector-contrib.tests.version;
  codex-daemon =
    pkgs.runCommand "codex-daemon"
      { nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.websockets ])) ]; }
      ''
        python3 ${./codex-daemon.py} ${lib.getExe pkgs.codex}
        touch "$out"
      '';
  zsh-agent-shell =
    pkgs.runCommand "zsh-agent-shell"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.zsh
        ];
      }
      ''
        python ${./zsh-agent-shell.py} ${lib.getExe pkgs.zsh} ${../modules/home/programs/zsh/core/agent-glob.zsh}
        touch "$out"
      '';
  native-output = import ./native-output.nix { inherit pkgs; };
  pi-extensions = import ./pi-extensions.nix { inherit pkgs; };
  onepassword = import ./onepassword.nix { inherit pkgs; };
  nh = import ./nh.nix { inherit pkgs; };
  strands = pkgs.strands-cli;
  task-commands = import ./task-commands.nix { inherit pkgs; };
  mail-actions = import ./mail.nix { inherit pkgs; };
  git-ai-integration =
    pkgs.runCommand "git-ai-integration"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.git
          pkgs.changes
          pkgs.traces
          pkgs.traces-providers
          pkgs.git-ai
          pkgs.nushell
          pkgs.coreutils
        ];
      }
      ''
        python3 ${./git-ai-integration.py} ${pkgs.git-ai}/bin/git-ai ${pkgs.git-ai-gate}/bin/git-ai-gate \
          ${../modules/home/programs/git-ai/changes-provider.py} \
          ${../modules/home/programs/nushell/attribution.nu} ${../modules/home/programs/nushell/storage.nu}
        touch "$out"
      '';
  git-ai-maintenance =
    pkgs.runCommand "git-ai-maintenance" { nativeBuildInputs = [ pkgs.python3 ]; }
      ''
        python3 ${./git-ai-maintenance.py} ${../modules/home/programs/git-ai/maintain-metrics.py}
        touch "$out"
      '';
  task-queue = import ./task-queue.nix { inherit pkgs; };
  task-queue-picker =
    pkgs.runCommand "task-queue-picker-test"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.pueue
          pkgs.zmx
          pkgs.bash
          pkgs.coreutils
        ];
      }
      ''
        python3 ${./task-queue-picker.py} ${pkgs.task-queue-picker}/bin/task-queue-picker ${pkgs.sysinit-gotools}/bin/task-queue
        touch "$out"
      '';
  nushell-utilities =
    pkgs.runCommand "nushell-utilities"
      {
        nativeBuildInputs = [
          pkgs.nushell
          pkgs.coreutils
        ];
      }
      ''
        export HOME="$TMPDIR"
        export TASK_BINARY=${lib.getExe pkgs.taskwarrior-cli}
        nu --no-config-file -c "use ${../modules/home/programs/utils/dev/ere-setup.nu} configure; use ${../modules/home/programs/utils/dev/task-context.nu} [backup restore]; use ${../modules/home/programs/utils/system/cache-maintain.nu} [maintain allocated-bytes]; source ${./nushell-utilities.nu}"
        nu --no-config-file ${./ty.nu} ${../modules/home/programs/utils/dev/ty.nu}
        touch "$out"
      '';
  opencode = import ./opencode.nix { inherit pkgs; };
  utility-contracts = import ./utility-contracts.nix { inherit pkgs; };
  ty =
    pkgs.runCommand "ty-cli"
      {
        nativeBuildInputs = [
          pkgs.sysinit-utils
          pkgs.gnugrep
        ];
      }
      ''
        ${pkgs.sysinit-utils}/bin/ty --help | grep -F 'ty catalog'
        touch "$out"
      '';
  slk-config =
    pkgs.runCommand "slk-config-test"
      {
        nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.tomlkit ])) ];
      }
      ''
        python ${./slk.py} ${../modules/home/programs/slk-setup.py}
        touch $out
      '';

  firefox = import ./firefox.nix { inherit pkgs darwinConfigurations nixosConfigurations; };
  editor-composition = import ./editor-composition.nix { inherit pkgs homeManagerLib; };
  slack-guard = import ./slack-guard.nix { inherit pkgs; };
  pr-workflow =
    pkgs.runCommand "pr-workflow-test"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.git
          pkgs.nushell
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        python ${./pr-workflow.py} ${../modules/home/programs/gh-pr-diff.py} ${../modules/home/programs/llm/runtime/ask-terminal.py} ${nuFunctions}
        touch "$out"
      '';
  gh-dash-pr = pkgs.runCommand "gh-dash-pr-test" { nativeBuildInputs = [ pkgs.sysinit-gh-dash ]; } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    if gh-dash https://github.com/owner/repo/issues/1 > stdout 2> stderr; then
      echo "gh-dash accepted an issue URL as a PR" >&2
      exit 1
    fi
    grep -F 'points to an issue, only pull requests are supported' stderr
    touch "$out"
  '';
  url-routing = pkgs.runCommand "url-routing-test" { nativeBuildInputs = [ pkgs.lua5_4 ]; } ''
    lua ${./url-routing.lua} ${../modules/darwin/home/hammerspoon/lua/sysinit/pkg/url_routing.lua}
    touch "$out"
  '';
  macos-notifier =
    pkgs.runCommand "macos-notifier-test"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.bash
        ];
      }
      ''
        python3 ${./macos-notifier.py} ${../modules/home/programs/llm/runtime/macos-notifier.sh}
        touch "$out"
      '';
  hammerspoon-startup =
    pkgs.runCommand "hammerspoon-startup-test" { nativeBuildInputs = [ pkgs.lua5_4 ]; }
      ''
        lua ${./hammerspoon-switcher.lua} ${../modules/darwin/home/hammerspoon/lua/sysinit/pkg/core/init.lua}
        lua ${./hammerspoon-startup.lua} ${../modules/darwin/home/hammerspoon/lua/sysinit/pkg/core/startup.lua}
        touch "$out"
      '';
  jankyborders =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.jankyborders
    else
      evalOnly "jankyborders-not-applicable";
  shell-completions = import ./shell-completions.nix { inherit pkgs; };
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
  atuin = import ./atuin.nix {
    inherit lib pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };
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
  app-copy-state =
    pkgs.runCommand "app-copy-state-test"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.rsync
        ];
      }
      ''
        python3 ${./app-copy-state.py} ${../modules/home/app-copy-state.py}
        touch "$out"
      '';
  github-runner-guard = import ./github-runner-guard.nix { inherit pkgs; };

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
    assert lib.assertMsg (
      commandPath.homeEntriesFor true "/etc/profiles/per-user/roshan/bin" "/Users/roshan"
      == darwinShellPath
      &&
        commandPath.homeEntriesFor false "/etc/profiles/per-user/roshan/bin" "/home/roshan"
        == linuxShellPath
    ) "agent and shell paths must use the same entries";
    assert lib.assertMsg (
      builtins.elem "/Users/roshan/go/bin" darwinShellPath
      && builtins.elem "/home/roshan/go/bin" linuxShellPath
      && builtins.head darwinShellPath == "/etc/profiles/per-user/roshan/bin"
      && builtins.length darwinShellPath == builtins.length (lib.unique darwinShellPath)
    ) "user tools must be available after managed commands without duplicate paths";
    evalOnly "command-path-order";

  mcp-harness-suppression =
    assert lib.assertMsg (
      ampMcpServers.kept.command == "kept"
    ) "the amp MCP set dropped the kept server";
    assert lib.assertMsg (
      !(ampMcpServers ? suppressed)
    ) "the amp MCP set carries suppressed, which harnessSuppressedServers removes";
    evalOnly "mcp-harness-suppression";
  editor-config = import ./editor-config.nix { inherit pkgs; };
  skill-catalog = import ./skill-catalog.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };
  harness-instructions = import ./harness-instructions.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
    inherit (pkgs) lib;
  };
  codex-config = import ./codex-config.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
    inherit (pkgs) lib;
  };
  harness-settings = import ./harness-settings.nix {
    inherit pkgs darwinConfigurations nixosConfigurations;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };
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
  go-tests = pkgs.sysinit-gotools;
  ast-grep-installed-rules = import ./ast-grep.nix { inherit pkgs; };
  package-set-composition = import ./package-set.nix {
    inherit pkgs darwinConfigurations nixosConfigurations;
  };
  nixos-launcher = import ./nixos-launcher.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };
  gate-config = import ./gate-config.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  llm-composition = import ./llm-composition.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  nushell-managed-tools = import ./nushell-managed-tools.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  nushell-completions = import ./nushell-completions.nix {
    inherit pkgs;
    inherit (pkgs) lib;
    fzf = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config.programs.fzf.package;
  };
  nushell-externs = import ./nushell-externs.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  wezterm-shell = import ./wezterm-shell.nix {
    inherit pkgs darwinConfigurations nixosConfigurations;
  };
  nushell-wezterm =
    let
      shellConfig = pkgs.writeText "wezterm-check-config.nu" ''
        $env.config.shell_integration = ('${
          builtins.toJSON
            homeConfigurations.${
              "dev-" + pkgs.stdenv.hostPlatform.system
            }.config.programs.nushell.settings.shell_integration
        }' | from json)
        $env.config.show_banner = false
        use ${nuFunctions} *
      '';
    in
    pkgs.runCommand "nushell-wezterm"
      {
        nativeBuildInputs = [
          pkgs.nushell
          pkgs.python3
        ];
      }
      ''
        python3 ${./nushell-wezterm.py} ${shellConfig}
        touch "$out"
      '';
  nushell-plugin-registration = pkgs.runCommand "nushell-plugin-registration" { } ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
    touch "$TMPDIR/plugin.msgpackz"
    ${lib.getExe pkgs.nushell} --plugin-config "$TMPDIR/plugin.msgpackz" \
      --commands 'plugin add ${lib.getExe pkgs.nu-plugin-nuvim}'
    ${lib.getExe pkgs.nushell} --plugin-config "$TMPDIR/plugin.msgpackz" \
      --commands 'plugin use nuvim; nuvim servers | ignore'
    touch "$out"
  '';

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
  zmx-nushell =
    pkgs.runCommand "zmx-nushell"
      {
        nativeBuildInputs = [
          pkgs.nushell
          pkgs.gnugrep
        ];
      }
      ''
        mkdir -p fake-bin
        cat > fake-bin/wezterm-pane-name <<'SH'
        #!/bin/sh
        printf '%s\n' quiet-falcon
        SH
        cat > fake-bin/zmx <<'SH'
        #!/bin/sh
        printf '%s\n' "$*" >> "$ZMX_TEST_LOG"
        SH
        chmod +x fake-bin/wezterm-pane-name fake-bin/zmx
        export PATH="$PWD/fake-bin:$PATH"
        export ZMX_TEST_LOG="$TMPDIR/zmx-args"
        export WEZTERM_PANE=18
        export ZMX_SESSION_PREFIX=

        nu --no-config-file -c 'use ${nuFunctions} *; persist'
        grep -Fx 'attach quiet-falcon' "$ZMX_TEST_LOG"

        : > "$ZMX_TEST_LOG"
        export ZMX_SESSION=quiet-falcon
        nu --no-config-file -c 'use ${nuFunctions} *; persist'
        test ! -s "$ZMX_TEST_LOG"

        unset ZMX_SESSION
        nu --no-config-file -c 'use ${nuFunctions} *; if ((scope commands | where name == "zmx" | length) != 0) { error make {msg: "zmx must remain an external command"} }; zmx list --short'
        grep -Fx 'list --short' "$ZMX_TEST_LOG"
        touch "$out"
      '';
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  codex-mcp-capabilities = pkgs.runCommand "codex-mcp-capabilities" { } ''
    ${lib.getExe pkgs.python3} ${./codex-mcp-capabilities.py} ${lib.getExe pkgs.codex}
    touch "$out"
  '';
}
