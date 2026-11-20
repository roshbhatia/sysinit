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
  nuCheck = import ./lib.nix { inherit pkgs; };
  nativeCheck = import ./native.nix { inherit pkgs; };

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
  sunshine-apps = nuCheck {
    name = "sunshine-apps-check";
    script = "sunshine-apps.nu";
    arguments = [ ../modules/nixos/home/sunshine-apps-gen.nu ];
    inputs = [
      pkgs.curl
      pkgs.imagemagick
    ];
  };

  update-flakes = nativeCheck {
    name = "update-flakes-check";
    inputs = [ pkgs.git ];
    commands = [
      [
        "nu"
        "--no-config-file"
        ../hack/test-update-flakes.nu
        ../hack/update-flakes.nu
        ../hack/fixtures/update-flakes-command.nu
      ]
    ];
  };

  runner-operator = nuCheck {
    name = "runner-operator-check";
    script = "runner-operator.nu";
    arguments = [
      ../modules/nixos/runner-operator.nu
      ./fixtures/runner-kubectl.nu
    ];
  };
  nvfetcher-sources =
    let
      declared = builtins.attrNames (fromTOML (builtins.readFile ../nvfetcher.toml));
      generated = builtins.attrNames pkgs.nvfetcherSources;
      manifest = builtins.attrNames (builtins.fromJSON (builtins.readFile ../_sources/generated.json));
    in
    assert lib.assertMsg (
      declared == generated && declared == manifest
    ) "nvfetcher output must contain every configured source";
    nativeCheck {
      name = "nvfetcher-sources";
      commands = [
        [
          "nu"
          "--no-config-file"
          "${../hack}/test-github-release-with-assets.nu"
        ]
      ];
    };
  inherit (pkgs) leaf-reader;
  traces-opencode-runtime =
    assert pkgs.traces-providers.providers.opencode.providerRuntimeInputs == [ pkgs.opencode ];
    nuCheck {
      name = "traces-opencode-runtime";
      script = "command-contracts.nu";
      arguments = [
        "contains"
        "${pkgs.traces-providers}/bin/traces-provider-opencode"
        "${pkgs.opencode}/bin"
      ];
    };
  conductor = pkgs.conductor-cli;
  opentelemetry-collector = pkgs.opentelemetry-collector-contrib.tests.version;
  codex-daemon = nativeCheck {
    name = "codex-daemon";
    inputs = [ (pkgs.python3.withPackages (ps: [ ps.websockets ])) ];
    commands = [
      [
        "python3"
        ./codex-daemon.py
        (lib.getExe pkgs.codex)
      ]
    ];
  };
  zsh-agent-shell = nuCheck {
    name = "zsh-agent-shell";
    script = "zsh-agent-shell.nu";
    arguments = [
      (lib.getExe pkgs.zsh)
      ../modules/home/programs/zsh/core/agent-glob.zsh
    ];
    inputs = [ pkgs.zsh ];
  };
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
        nu --no-config-file ${./git-ai-integration.nu} ${pkgs.git-ai}/bin/git-ai ${pkgs.git-ai-gate}/bin/git-ai-gate \
          ${../modules/home/programs/git-ai/changes-provider.nu} \
          ${../modules/home/programs/nushell/attribution.nu} ${../modules/home/programs/nushell/storage.nu}
        touch "$out"
      '';
  git-ai-maintenance =
    pkgs.runCommand "git-ai-maintenance"
      {
        nativeBuildInputs = [
          pkgs.nushell
          pkgs.sqlite
          pkgs.coreutils
        ];
      }
      ''
        nu --no-config-file -c 'use ${../modules/home/programs/git-ai/maintain-metrics.nu} maintain; source ${./git-ai-maintenance.nu}; check ${../modules/home/programs/git-ai/maintain-metrics.nu} ${./fixtures/wait-for-file.nu}'
        touch "$out"
      '';
  tq = import ./tq.nix { inherit pkgs; };
  tq-browser = nativeCheck {
    name = "tq-browser-test";
    inputs = [
      (pkgs.python3.withPackages (ps: [ ps.pyte ]))
      pkgs.pueue
    ];
    commands = [
      [
        "python3"
        ./tq-browser.py
        "${pkgs.sysinit-gotools}/bin/tq"
      ]
    ];
  };

  tq-picker = nativeCheck {
    name = "tq-picker-test";
    inputs = [
      pkgs.python3
      pkgs.pueue
      pkgs.wezterm
      pkgs.bash
    ];
    commands = [
      [
        "python3"
        ./tq-picker.py
        "${pkgs.tq-picker}/bin/tq-picker"
        "${pkgs.sysinit-gotools}/bin/tq"
      ]
    ];
  };
  nushell-utilities = nativeCheck {
    name = "nushell-utilities";
    environment.TASK_BINARY = lib.getExe pkgs.taskwarrior-cli;
    commands = [
      [
        "nu"
        "--no-config-file"
        "-c"
        "use ${../modules/home/programs/utils/dev/ere-setup.nu} configure; use ${../modules/home/programs/utils/dev/task-context.nu} [backup restore]; use ${../modules/home/programs/utils/system/cache-maintain.nu} [maintain allocated-bytes]; source ${./nushell-utilities.nu}"
      ]
      [
        "nu"
        "--no-config-file"
        "${./ty.nu}"
        "${../modules/home/programs/utils/dev/ty.nu}"
      ]
    ];
  };
  opencode = import ./opencode.nix { inherit pkgs; };
  utility-contracts = import ./utility-contracts.nix { inherit pkgs; };
  notification-assets = import ./notification-assets.nix { inherit pkgs; };
  ty = nuCheck {
    name = "ty-cli";
    script = "command-contracts.nu";
    arguments = [
      "help"
      "${pkgs.sysinit-utils}/bin/ty"
      "ty catalog"
    ];
  };
  slk-config = nuCheck {
    name = "slk-config-test";
    script = "slk.nu";
    arguments = [ ../modules/home/programs/slk-setup.py ];
    inputs = [ (pkgs.python3.withPackages (p: [ p.tomlkit ])) ];
  };

  firefox = import ./firefox.nix { inherit pkgs darwinConfigurations nixosConfigurations; };
  editor-composition = import ./editor-composition.nix { inherit pkgs homeManagerLib; };
  slack-guard = import ./slack-guard.nix { inherit pkgs; };
  pr-workflow = nativeCheck {
    name = "pr-workflow-test";
    inputs = [
      pkgs.git
      pkgs.flock
    ];
    commands = [
      [
        "nu"
        "--no-config-file"
        "${./pr-workflow.nu}"
        "${../modules/home/programs/gh-pr-diff.nu}"
        "${../modules/home/programs/llm/runtime/ask-terminal.nu}"
        "${nuFunctions}"
        "${./fixtures/review-tools.nu}"
      ]
    ];
  };
  gh-dash-pr = nuCheck {
    name = "gh-dash-pr-test";
    script = "command-contracts.nu";
    arguments = [ "gh-dash" ];
    inputs = [ pkgs.sysinit-gh-dash ];
  };
  gh-pr-state = nuCheck {
    name = "gh-pr-state-test";
    script = "gh-pr-state.nu";
    arguments = [ ../modules/home/programs/gh-pr-state.nu ];
  };
  url-routing = nativeCheck {
    name = "url-routing-test";
    inputs = [ pkgs.lua5_4 ];
    commands = [
      [
        "lua"
        ./url-routing.lua
        ../modules/darwin/home/hammerspoon/lua/sysinit/pkg/url_routing.lua
      ]
    ];
  };
  macos-notifier = nuCheck {
    name = "macos-notifier-test";
    script = "macos-notifier.nu";
    arguments = [
      ../modules/home/programs/llm/runtime/macos-notifier.sh
      ./fixtures/notifier-command.nu
    ];
    inputs = [ pkgs.bash ];
  };
  hammerspoon-startup = nativeCheck {
    name = "hammerspoon-startup-test";
    inputs = [ pkgs.lua5_4 ];
    commands = [
      [
        "lua"
        ./hammerspoon-switcher.lua
        ../modules/darwin/home/hammerspoon/lua/sysinit/pkg/core/init.lua
      ]
      [
        "lua"
        ./hammerspoon-startup.lua
        ../modules/darwin/home/hammerspoon/lua/sysinit/pkg/core/startup.lua
      ]
    ];
  };
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
          pkgs.nushell
          pkgs.zsh
          pkgs.coreutils
        ];
      }
      ''
        nu --no-config-file ${./completion-cache.nu} ${../modules/home/programs/zsh/core/compinit.zsh}
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
    let
      plugin = lib.getExe pkgs.nushellPlugins.formats;
      command = pkgs.writeShellScript "defaults-fixture" ''
        exec ${lib.getExe pkgs.nushell} --no-config-file --plugins ${plugin} ${./fixtures/defaults-command.nu} "$@"
      '';
    in
    pkgs.runCommand "incremental-defaults-test"
      {
        nativeBuildInputs = [ pkgs.nushell ];
        DEFAULTS_TEST_PLUGIN = plugin;
      }
      ''
        nu --no-config-file --plugins "$DEFAULTS_TEST_PLUGIN" ${./incremental-defaults.nu} ${../modules/darwin/defaults-incremental.nu} ${command}
        touch "$out"
      '';
  homebrew-reconcile =
    pkgs.runCommand "homebrew-reconcile-test"
      {
        nativeBuildInputs = [
          pkgs.nushell
          pkgs.coreutils
          pkgs.bash
        ];
      }
      ''
        nu --no-config-file ${./homebrew-reconcile.nu} \
          ${../modules/darwin/reconcile-homebrew.sh} ${./fixtures/homebrew-command.nu}
        touch "$out"
      '';
  app-copy-state =
    let
      command = pkgs.writeShellScript "app-copy-fixture" ''
        exec ${lib.getExe pkgs.nushell} --no-config-file ${./fixtures/app-copy-command.nu} "$@"
      '';
    in
    pkgs.runCommand "app-copy-state-test"
      {
        nativeBuildInputs = [
          pkgs.nushell
          pkgs.coreutils
          pkgs.rsync
        ];
      }
      ''
        nu --no-config-file ${./app-copy-state.nu} ${../modules/home/app-copy-state.nu} ${command}
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
  egm-plugins = import ./egm-plugins.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
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
    nativeCheck {
      name = "nushell-wezterm";
      inputs = [ pkgs.python3 ];
      commands = [
        [
          "python3"
          ./nushell-wezterm.py
          shellConfig
        ]
      ];
    };
  nushell-plugin-registration = nuCheck {
    name = "nushell-plugin-registration";
    script = "command-contracts.nu";
    arguments = [
      "plugins"
      (lib.getExe pkgs.nu-plugin-nuvim)
    ];
  };

  system-generation-prune =
    if pkgs.stdenv.hostPlatform.isDarwin then
      import ./system-generation-prune.nix { inherit pkgs; }
    else
      evalOnly "system-generation-prune-not-applicable";
  nushell-command-surface = nuCheck {
    name = "nushell-command-surface";
    script = "command-contracts.nu";
    arguments = [
      "command-surface"
      nuFunctions
    ];
  };
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  codex-mcp-capabilities = nativeCheck {
    name = "codex-mcp-capabilities";
    inputs = [ pkgs.python3 ];
    commands = [
      [
        "python3"
        ./codex-mcp-capabilities.py
        (lib.getExe pkgs.codex)
      ]
    ];
  };
}
