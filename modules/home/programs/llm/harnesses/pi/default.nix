{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  piKeys = import ./settings-keys.nix;
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Extension TypeScript comes from the installed pi package, which ships its own
  # fetchFromGitHub, and that pin drifted to 0.74.0 while the binary ran 0.82.1:
  # an extension written against one extension API and loaded by another fails at
  # load time, not at build time. One source removes that class of defect, and a
  extensionsDir = "${pkgs.pi-coding-agent}/pi/examples/extensions";

  # Gemini OAuth (Google Cloud Code Assist) as a provider, restoring what pi
  # dropped from core. Pinned from source rather than `pi install npm:...`:
  # an imperative install lands outside the generation and drifts, and this
  # package needs no node_modules to run. Its only non-pi dependency,
  # `@google/genai`, appears once as `import type`, which is erased before
  # execution; everything else is under its own src/vendor/.
  piGeminiAuth = pkgs.fetchFromGitHub {
    owner = "qraxiss";
    repo = "pi-gemini-auth";
    rev = "3fa07ac080594744a39c736a72885388fb0c1314";
    hash = "sha256-HjiSEC1loWfiziR47LLLx9N4y4Ly25HdWXLXtdqDZLQ=";
  };

  # pi resolves a directory extension through its package.json `pi.extensions`
  # key, the same shape openspec-sidebar uses. Assert it rather than trust it:
  # upstream renaming that key would leave a directory installed that pi
  # silently never loads.
  assertGeminiAuthEntrypoint =
    if !builtins.pathExists "${piGeminiAuth}/src/index.ts" then
      throw "pi.nix: pi-gemini-auth no longer ships src/index.ts; re-pin and check its package.json `pi.extensions`."
    else
      true;

  # confirm-destructive intentionally not in this list — replaced by
  # @gotgenes/pi-permission-system below (bash-AST-aware gate). The two
  # cannot both intercept tool calls without conflict.
  # `mac-system-theme` is deliberately NOT here. It calls `ctx.ui.setTheme` on
  # session_start and polls every 2 seconds, and pi persists an extension-driven
  # theme change to settings (pi CHANGELOG 0.54.1). With `theme` declared and
  # enforced that is a silent fight: pi writes dark, the next activation writes the
  # generated theme back, the next session writes dark. The generated theme would be
  # active in zero sessions. This host declares `appearance = "dark"` with a dark
  # scheme, so following the macOS appearance was already incoherent with the rest of
  # the system. The `pi-no-theme-writer` check fails the build if it comes back.
  extensions = import ./vendored-extensions.nix;

  # Deliberately NOT vendored, both for the same reason `confirm-destructive` is
  # excluded above: each binds `tool_call`, and so does
  # @gotgenes/pi-permission-system, which owns tool-call interception here. Two
  # handlers on that event cannot both gate without conflict.

  missingExtensions = lib.filter (n: !builtins.pathExists "${extensionsDir}/${n}.ts") extensions;
  assertExtensionsExist =
    if missingExtensions != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " missingExtensions} named in `extensions` but absent from the installed pi package. A version bump may have renamed or removed it."
    else
      true;

  extensionFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".pi/agent/extensions/${name}.ts" {
        source = "${extensionsDir}/${name}.ts";
        force = true;
      }
    ) extensions
  );

  # The bridge's install path. `notify.nix` lists pi as bridged and pi's own
  # `notify` producer is gone from `extensions` above, so an install entry that
  # disappears leaves pi with no notifier at all. The source file existing is
  # not enough: the entry below is what reaches $HOME.
  piBridgePath = ".pi/agent/extensions/sysinit-notify.ts";

  assertPiBridgeInstalled =
    if !(customExtensionFiles ? ${piBridgePath}) then
      throw "pi.nix: ${piBridgePath} is not installed, but notify.nix lists pi as bridged and its own notify extension is retired. Pi would have no notifier."
    else
      true;

  # Custom local extensions authored in this repo and installed under the
  # same ~/.pi/agent/extensions/ root as the vendored upstream ones.
  customExtensionFiles = {
    # Bridges pi onto the shared notifier. Replaces the upstream `notify`
    # extension, which is dropped from the vendored list above in the same
    # edit so pi is never left with no producer.
    ".pi/agent/extensions/sysinit-notify.ts" = {
      source = ./extensions/sysinit-notify.ts;
      force = true;
    };
    # Diff review in a native multiplexer split.
    ".pi/agent/extensions/diff-review.ts" = {
      source = ./extensions/diff-review.ts;
      force = true;
    };
    ".pi/agent/extensions/spec-tools.ts" = {
      source = ./extensions/spec-tools.ts;
      force = true;
    };
    ".pi/agent/extensions/openspec-sidebar" = {
      source = ./extensions/openspec-sidebar;
      recursive = true;
      force = true;
    };
    ".pi/agent/extensions/pi-gemini-auth" = {
      source = piGeminiAuth;
      recursive = true;
      force = true;
    };
  };

  # Bound as an attrset before serialization so `assertThemeSelected` can compare
  # the theme's OWN `name` field against `piThemeName`. Serializing inline made that
  # field unreachable, so a hardcoded name could drift from the selected setting and
  # nothing caught it.
  stylixThemeAttrs =
    let
      c = config.lib.stylix.colors;
      hex = name: "#${c.${name}}";
    in
    {
      "$schema" =
        "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
      name = piThemeName;
      vars = {
        primary = hex "base0D";
        secondary = hex "base03";
        accent = hex "base0D";
        muted = hex "base03";
        dim = hex "base04";
        success = hex "base0B";
        error = hex "base08";
        warning = hex "base0A";
        selectedBg = hex "base01";
        userMsgBg = hex "base01";
        toolPendingBg = hex "base02";
        toolSuccessBg = hex "base01";
        toolErrorBg = hex "base01";
        customMsgBg = hex "base02";
      };
      colors = {
        accent = "accent";
        border = "primary";
        borderAccent = hex "base0C";
        borderMuted = "dim";
        success = "success";
        error = "error";
        warning = "warning";
        muted = "secondary";
        dim = "dim";
        text = "";
        thinkingText = "secondary";

        selectedBg = "selectedBg";
        userMessageBg = "userMsgBg";
        userMessageText = "";
        customMessageBg = "customMsgBg";
        customMessageText = "";
        customMessageLabel = "primary";
        toolPendingBg = "toolPendingBg";
        toolSuccessBg = "toolSuccessBg";
        toolErrorBg = "toolErrorBg";
        toolTitle = "primary";
        toolOutput = "secondary";

        mdHeading = hex "base0A";
        mdLink = "primary";
        mdLinkUrl = "dim";
        mdCode = hex "base0C";
        mdCodeBlock = "";
        mdCodeBlockBorder = "secondary";
        mdQuote = "secondary";
        mdQuoteBorder = "secondary";
        mdHr = "secondary";
        mdListBullet = hex "base0C";

        toolDiffAdded = "success";
        toolDiffRemoved = "error";
        toolDiffContext = "secondary";

        syntaxComment = "secondary";
        syntaxKeyword = hex "base0E";
        syntaxFunction = hex "base0D";
        syntaxVariable = hex "base08";
        syntaxString = hex "base0B";
        syntaxNumber = hex "base09";
        syntaxType = hex "base0A";
        syntaxOperator = hex "base05";
        syntaxPunctuation = "secondary";

        thinkingOff = "dim";
        thinkingMinimal = "secondary";
        thinkingLow = hex "base0D";
        thinkingMedium = hex "base0C";
        thinkingHigh = hex "base0E";
        thinkingXhigh = hex "base08";

        bashMode = hex "base0A";
      };
      export = {
        pageBg = hex "base00";
        cardBg = hex "base01";
        infoBg = hex "base02";
      };
    };

  # ---------------------------------------------------------------------------
  # Pi packages - pre-fetched into the Nix store as local paths.
  # Pi loads them via local path entries in settings.json, so no runtime network
  # access is needed.  Each package is either a plain source fetch (no runtime

  # Helper: fetch an npm package tarball from the registry and extract it.
  # npm tarballs have a top-level "package/" dir; fetchzip strips it so
  # the derivation root contains package.json directly. Scoped packages
  # use `@scope/basename` for the URL path but only `basename` in the
  fetchNpmPkg =
    {
      name,
      version,
      hash,
    }:
    let
      basename = lib.last (lib.splitString "/" name);
    in
    pkgs.fetchzip {
      url = "https://registry.npmjs.org/${name}/-/${basename}-${version}.tgz";
      inherit hash;
    };

  # Helper: build an npm package that has runtime dependencies.
  # The package-lock.json is injected via postPatch because npm registry
  # tarballs do not include one, but buildNpmPackage requires it for npm ci.
  buildNpmPkg =
    {
      name,
      version,
      hash,
      npmDepsHash,
      lockFile,
    }:
    pkgs.buildNpmPackage {
      pname = name;
      inherit version npmDepsHash;
      src = fetchNpmPkg { inherit name version hash; };
      postPatch = ''
        cp ${lockFile} package-lock.json
      '';
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

  mkFetchedNpmPackage =
    name: version: hash:
    fetchNpmPkg {
      inherit name version hash;
    };

  mkBuiltNpmPackage =
    name: version: hash: npmDepsHash: lockFile:
    buildNpmPkg {
      inherit
        name
        version
        hash
        npmDepsHash
        lockFile
        ;
    };

  piPackages = {

    # Git package with runtime npm deps - package-lock.json is in the repo
    mermaid = pkgs.buildNpmPackage {
      pname = "pi-mermaid";
      version = "0.3.0";
      src = pkgs.fetchFromGitHub {
        owner = "Gurpartap";
        repo = "pi-mermaid";
        rev = "34cab3ae794422d43707f129120a73ea39f51742";
        hash = "sha256-tXFYBlFjXUR4TF6k0FWC9T6kxWjlF/kAEt/Q9/nUCJY=";
      };
      npmDepsHash = "sha256-rHFkSF+v9MeXXfq8x7Vl9al7EmLgGrC1AMH+WVyxviA=";
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

    # npm packages - source only (no runtime deps beyond pi's bundled ones)
    context =
      mkFetchedNpmPackage "pi-context" "1.1.4"
        "sha256-pdRI1D2KIOJVV164DKpzXAQneOOEypB2GXqFzGRvasc=";
    subagents =
      mkFetchedNpmPackage "pi-subagents" "0.24.2"
        "sha256-cRcUl0gNmk4gqStqNffT6FQOozjAMuETe3OeNaQMXfA=";
    readlineSearch =
      mkFetchedNpmPackage "pi-readline-search" "0.1.0"
        "sha256-HxomHcIceZX68M0f0ZcRJSiqDzqCI0p+wcyq8CVL514=";
    threads =
      mkFetchedNpmPackage "pi-threads" "0.2.1"
        "sha256-MF++ANxMplxx0qydKoozrnNTFtb4HQ/0s923cGrsPyM=";
    librarian =
      mkFetchedNpmPackage "pi-librarian" "1.3.7"
        "sha256-Obn+DyQD1WCptZO5t0YgUOdpGULNYfPxUA7NeGT7GfQ=";
    askUser =
      mkFetchedNpmPackage "pi-ask-user" "0.11.0"
        "sha256-R1TN2GWrwv3UhlAC0Ym1nMZABi/IrLxtD6EYxbDEfm8=";
    toolDisplay =
      mkFetchedNpmPackage "pi-tool-display" "0.3.6"
        "sha256-6ykaEl8IlwH667YQ+CBO/I/0rTDlIues4fYZDKJg2JE=";
    subdirContext =
      mkFetchedNpmPackage "pi-subdir-context" "1.1.7"
        "sha256-nPHuANl4j5Ank2ccLUQFLxRIxTPJCLF3G73NpU8xHnI=";

    # npm packages with runtime deps - lock files stored in ./locks/
    # pi-web-access: web search + content fetch (URL/PDF/GitHub/YouTube).
    # Replaces pi-webfetch-to-markdown and adds web search — a capability gap in
    # pi vs Claude/Codex. Keep pi-librarian; disable the bundled librarian skill
    # via ~/.pi/web-search.json if it collides. Inline (not mkBuiltNpmPackage)
    webAccess = pkgs.buildNpmPackage {
      pname = "pi-web-access";
      version = "0.13.0";
      src = fetchNpmPkg {
        name = "pi-web-access";
        version = "0.13.0";
        hash = "sha256-6d/cX9OYHIxZ81fJgEu4L7DzMF/o63AL2/n/3zHs0DU=";
      };
      postPatch = ''
        cp ${./locks/pi-web-access.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-8onTvv7nUrTXMGvwkMkPEYc+mtpxolzF6Z9EuuB9pbs=";
      npmFlags = [
        "--ignore-scripts"
        "--legacy-peer-deps"
      ];
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

    # Phase B additions (zero-dep extensions) — load order positions are
    # set via piPackagePaths array order below.

    # pi-btw: /btw spawns a parallel sub-session with tools inherited from
    # the parent. Use for tangents that shouldn't break the main flow.
    btw = mkFetchedNpmPackage "pi-btw" "0.4.0" "sha256-8iAnayDUtK/BGl0ldJ9klOpItdCyV8qniSO+pXGslNo=";

    # @narumitw/pi-retry: classifies transient provider failures (Codex backend
    # errors, websocket limits, stalled streams) so pi's native retry recovers.
    # Zero deps; complements (does not replace) pi's built-in retry.
    piRetry =
      mkFetchedNpmPackage "@narumitw/pi-retry" "0.22.0"
        "sha256-TwMvcJLe4ldgRw8k6/bsQpJbkePKYww20CqZVQfvsAc=";

    # @monotykamary/pi-vcc: deterministic, LLM-free session compaction. It
    # intercepts Pi's native threshold compaction; do not also load Pi's
    # trigger-compact extension, which can attempt an invalid second compact.
    piVcc =
      mkFetchedNpmPackage "@monotykamary/pi-vcc" "0.8.1"
        "sha256-hsk/cwirBtfYK77aMoCoFncYhMsCff+HyBnpZD0GJKU=";

    # @samfp/pi-memory stays out: needs node:sqlite which bun lacks. Every
    # other pi-* memory package on npm at audit time still imports from
    # @mariozechner/* (pre-rename), so they break against pi 0.74's
    # @earendil-works/* runtime without a source patch the user has

    # @gotgenes/pi-permission-system 5.14.1: bash-AST-aware permission gate.
    # Imports @earendil-works/* (post-rename) so works with pi 0.74. The
    # earlier failure attributed to this package was actually node:sqlite
    # in @samfp/pi-memory at the same time — re-verified clean here.
    piPermissionSystem =
      mkBuiltNpmPackage "@gotgenes/pi-permission-system" "5.14.1"
        "sha256-/qNC6erD+Rl12JpLlFwe2N2PgaekpfMHHprnKozN1rk="
        "sha256-Dvu/wuGdwjBQsJCU0N8oI+a1EysJpHFkwLwUpgjJfso="
        ./locks/pi-permission-system.lock.json;

    # @benvargas/pi-openai-fast: /fast toggle for OpenAI priority service
    # tier on supported GPT-5.4 models. Inert when Anthropic is active.
    openaiFast =
      mkFetchedNpmPackage "@benvargas/pi-openai-fast" "1.0.2"
        "sha256-cUY9RGofE+zMlB1qcgkM55KJhEiVHnan9bWSXtvpQ4E=";

    # @benvargas/pi-openai-verbosity: per-model OpenAI Codex text-verbosity
    # overrides. Pairs with openaiFast. Inert when Anthropic is active.
    openaiVerbosity =
      mkFetchedNpmPackage "@benvargas/pi-openai-verbosity" "1.0.0"
        "sha256-FXjeNW4UVe5PwNjjr2pL6DrLcYkdNtr7yP4jTzQvyPw=";

    # Phase C additions (heavier packages with runtime npm deps).

    # @plannotator/pi-extension: interactive plan review with inline
    # annotations. Pairs with openspec-propose review point.
    plannotator =
      mkBuiltNpmPackage "@plannotator/pi-extension" "0.19.14"
        "sha256-kyiItKnuYMxp43+5wlC6BUDftp+mTxXG7PB3aEq9Qbg="
        "sha256-oiiZsd1UG1nIa7xhnOcUKpyr2J2qWbghXildxE036Ok="
        ./locks/plannotator.lock.json;

    # @firstpick/pi-extension-reverse-last: session-aware undo for write/
    # edit tool calls (/reverse-last). Complements git-checkpoint at the
    # in-session granularity.
    piReverseLast =
      mkBuiltNpmPackage "@firstpick/pi-extension-reverse-last" "0.1.4"
        "sha256-+NtvjE1W8roNwgR55hzzcJWM4xhSqtk9mKDEWCoEUUE="
        "sha256-k0e9qvB9tvt6qstrYnoH7tyOoB5qRwStzE+cBdRm7CQ="
        ./locks/pi-reverse-last.lock.json;

    # @heyhuynhgiabuu/pi-diff: scoped package, Shiki-powered syntax-highlighted
    # diffs with side-by-side split view for edit and unified view for write.
    diff = pkgs.buildNpmPackage {
      pname = "pi-diff";
      version = "0.3.0";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@heyhuynhgiabuu/pi-diff/-/pi-diff-0.3.0.tgz";
        hash = "sha256-lQ9V8DvaHCj7hG9q+SJwy7M9hDCOPXRfWTqBh9kjS9A=";
      };
      postPatch = ''
        cp ${./locks/pi-diff.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-DPZfPc5njMabDdo5UwX7UoWvHPwC261LhT8BsAm7U00=";
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };
  };

  # Load order matters (per design D3):
  # 1. Provider routing — openaiFast + openaiVerbosity + piRetry (inert for non-OpenAI)
  # 2. Compaction — piVcc (deterministic, LLM-free)
  # 3. Orchestration — pi-subagents
  #
  # The packages below were removed and are deliberately absent. Most were loaded
  # and doing nothing, which reads as a working capability:
  #   - pi-mcp-adapter: reads ~/.pi/agent/mcp.json, which this repository never
  #     writes. It found no server, and the only file left was a stale
  #     mcp-cache.json the sidebar then rendered as live. Wiring pi to the MCP
  #     catalog in lib/mcp-catalog.nix is a separate decision, not a revert.
  #   - @benvargas/pi-claude-code-use: patches Anthropic OAuth payloads.
  #     `defaultProvider` is openai-codex, so it wrapped the auth path for a
  #     provider that is never selected.
  #   - pi-dcp: a third extension mutating the message list, beside piVcc
  #     (compaction) and context (context management).
  #   - pi-interview: a second interactive prompt UI beside askUser.
  #   - taskplane: never configured on any host. No `.pi/task-runner.yaml` exists
  #     anywhere, which is why its statusline read `0 areas`. Its task format
  #     (PROMPT.md/STATUS.md plus a dependency map) duplicates what openspec and
  #     `specutil next` already provide, its parallelism duplicates pi-subagents, and
  #     seshy already gives worktree-per-session. What it uniquely added was a
  #     dashboard, cross-model review, and auto-merge, none of which were in use.
  #   - pi-rtk-optimizer: this one was working, and that was the problem. In
  #     `mode: "rewrite"` its tool_call handler reassigns event.input.command, so
  #     `git status` runs as `rtk git status`. The permission gate is safe by load
  #     order alone (piPermissionSystem is first, so it matches the ORIGINAL text),
  #     which is a thin margin to rest on. The durable objection is the transcript:
  #     it notifies every rewrite, teaching the model the `rtk <cmd>` form, and
  #     every deny glob in allowlist.nix is anchored on `git ` — `rtk git push
  #     --force` matches none of the 13, so under yoloMode it auto-approves.
  #     Its second half, outputCompaction, truncated at 12k chars and carried
  #     filterBuildOutput/aggregateTestOutput, which is how a failing check gets
  #     read as passing; pi-diff and pi-tool-display already own that rendering.
  #     Its peerDependencies also cap at pi ^0.80.0 against the pinned 0.82.1.
  #     `pkgs.rtk` went with it: nothing else consumed it.
  #   - pi-annotated-reply: eight commands and zero hooks, so purely
  #     command-driven, and `/reply-diff` plus `/reply-diff-editor` duplicate what
  #     `ctrl+b` now does through neovim and diffnote. Nothing in this repo's
  #     skills, docs, or instructions routes to any of its commands.
  #   - @juicesharp/rpiv-advisor: one manually-invoked `/advisor` command, paid for
  #     with a `before_agent_start` system-prompt injection on EVERY agent start.
  #     The adversarial-review skill and pi-subagents already cover second-opinion
  #     review, and nothing routes to `/advisor` either.
  piPackagePaths = with piPackages; [
    # 1. Permission gate — MUST load first to wrap all tool calls below.
    "${piPermissionSystem}"
    # 2. Provider routing (inert when target provider not active).
    "${openaiFast}"
    "${openaiVerbosity}"
    "${piRetry}"
    # 2b. Compaction — load early so the session_before_compact hook registers.
    "${piVcc}"
    # 3. Orchestration.
    "${piPackages.subagents}"
    # 5. UI / workflow.
    "${plannotator}"
    "${btw}"
    "${piReverseLast}"
    # 6. Tool providers.
    "${toolDisplay}"
    "${diff}"
    "${webAccess}"
    # 7. Content utilities.
    "${context}"
    "${subdirContext}"
    "${mermaid}"
    "${readlineSearch}"
    "${threads}"
    "${librarian}"
    "${askUser}"
  ];

  # Extensions that hook `context`, in the order pi loads them. pi runs handlers
  # in extension load order and each sees the previous one's mutations, so this
  # order decides what reaches the model. It was previously undocumented, and a
  # prior removal justified itself by calling pi-dcp "a third extension mutating
  # the message list" when the real count was six. That reasoning was wrong even
  # though the removal may not have been.
  #
  # Declared as data and asserted against `piPackagePaths` below, so an extension
  # added to the list without a decision about where it sits in the context
  # pipeline fails the build instead of silently landing wherever the list put it.
  contextHookOrder = [
    "pi-vcc" # compaction, earliest: everything downstream sees compacted input
    "pi-subagents" # delegation
    "plannotator/pi-extension" # plan annotations
    "pi-btw" # side conversations
    "pi-tool-display" # display only; its context hook sets thinking labels
    "pi-context" # context management, last
  ];

  # Read each package's declared name rather than matching its store path. Most
  # of these are plain source fetches whose path is a bare `-source` with no name
  # in it, so an infix test over paths silently matches nothing and the assertion
  # below would fire for every entry. (The same trap made an earlier "is rtk
  # installed?" check return false regardless of the answer.)
  installedPiPackageNames = map (
    p:
    let
      manifest = "${p}/package.json";
    in
    if builtins.pathExists manifest then
      (builtins.fromJSON (builtins.readFile manifest)).name or ""
    else
      ""
  ) piPackagePaths;

  # The context hookers as piPackagePaths actually orders them. Filtering the
  # INSTALLED list preserves load order; filtering the declared list would only
  # ever reproduce the declaration and could never disagree with it.
  contextHookActual = lib.filter (name: name != null) (
    map (
      installed: lib.findFirst (name: lib.hasInfix name installed) null contextHookOrder
    ) installedPiPackageNames
  );

  assertContextHookOrder =
    let
      missing = lib.subtractLists contextHookActual contextHookOrder;
    in
    if missing != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " missing} is declared in contextHookOrder but not installed. Remove it from the order, or restore the package."
    # Order, not merely membership. A presence-only assertion passed a declaration
    # with pi-tool-display and pi-btw the wrong way round, which is the one thing
    # the declaration exists to record: pi runs these handlers in load order and
    # each sees the previous one's mutations.
    else if contextHookActual != contextHookOrder then
      throw "pi.nix: contextHookOrder does not match the load order in piPackagePaths.\n  declared: ${lib.concatStringsSep " -> " contextHookOrder}\n  actual:   ${lib.concatStringsSep " -> " contextHookActual}"
    else
      true;

  assertGatesDisjoint =
    let
      hasPermSystem = builtins.any (p: lib.hasInfix "permission-system" (toString p)) piPackagePaths;
      hasConfirmDestructive = builtins.elem "confirm-destructive" extensions;
    in
    if hasPermSystem && hasConfirmDestructive then
      throw "pi.nix: @gotgenes/pi-permission-system and confirm-destructive cannot both be active. Remove one."
    else
      true;

  # @psg2/pi-costs: standalone CLI that analyses session JSONL logs for cost/token
  # summaries. Pre-compiled to dist/cli.js (bun target) — no npm deps, wraps with bun.
  piCosts = pkgs.stdenvNoCC.mkDerivation {
    pname = "pi-costs";
    version = "1.0.1";
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@psg2/pi-costs/-/pi-costs-1.0.1.tgz";
      hash = "sha256-J66+LmY5fJ+SAhzaDanQTPLftA0Az94cRTc4agI7PoI=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/pi-costs $out/bin
      cp -r . $out/lib/pi-costs/
      makeWrapper ${pkgs.bun}/bin/bun $out/bin/pi-costs \
        --add-flags "$out/lib/pi-costs/dist/cli.js"
      runHook postInstall
    '';
  };

  # nvim-pi: fast external editor wrapper — opens nvim without plugins.
  # Pi's externalEditor spawns $VISUAL/$EDITOR; nvim-pi overrides that with
  # --clean so lazy.nvim plugins don't load, eliminating the startup lag.
  nvimPi = pkgs.writeShellScriptBin "nvim-pi" ''
    exec ${pkgs.neovim}/bin/nvim --clean -c "set ft=markdown" "$@"
  '';

  # pi-acp is a standalone CLI tool (not a pi package) - exposed via home.packages.
  # dist/ is pre-compiled in the npm tarball; --ignore-scripts prevents npm ci
  # from triggering the prepare lifecycle hook (which would try to run tsup).
  piAcp = pkgs.buildNpmPackage {
    pname = "pi-acp";
    version = "0.0.26";
    src = fetchNpmPkg {
      name = "pi-acp";
      version = "0.0.26";
      hash = "sha256-37n4i+JY8I63xdXIL+BCFPohWYgugeW4ASB06y/+tjI=";
    };
    postPatch = ''
      cp ${./locks/pi-acp.lock.json} package-lock.json
    '';
    npmDepsHash = "sha256-IChKY574YL+/YeJben7ZrIsa0Y3ZPWDPDhEVNMwGDr4=";
    npmFlags = "--ignore-scripts";
    dontNpmBuild = true;
  };

  # Keys this repository has an opinion about. Anything absent here is left to
  # pi's own runtime, which is how `lastChangelogVersion` and the session
  # bookkeeping survive an activation.
  #
  # One definition for the generated theme. The setting, the theme's own `name`
  # field, and the install filename all derive from it, so the selection assertion
  # below is structural rather than a literal compared to a copy of itself.
  piThemeName = "stylix";

  # Owner's choice: no prompt on an ordinary command. It is safe to the extent the
  # DENY rules are, because yoloMode auto-approves `ask` and never `deny`, so the
  # destructive globs from lib/allowlist.nix remain the guard. formatForPi omits the
  # allow patterns under yolo for exactly that reason: with nothing to overlap, every
  # destructive glob is enforced rather than only the subset that could be ordered.
  yoloMode = true;

  piManagedSettings = {
    packages = piPackagePaths;

    # The generated theme, written to ~/.pi/agent/themes/${piThemeName}.json
    # below. Generating a theme and never selecting it left pi on "dark".
    theme = piThemeName;

    # Pi implements the Agent Skills standard and its own docs/skills.md gives
    # this exact array as the way to reuse another harness's tree. Without it,
    # pi advertised a skills root in its context that it could not load from.
    #
    # ONE root, deliberately. pi ALSO loads `~/.agents/skills` unconditionally
    # (docs/skills.md lists it as a global location and offers no way to turn it
    # off), so any skill present in both roots collided and pi skipped one copy,
    # reporting e.g. `"linear-project-update" collision`. The fix is upstream of
    # this setting: sysinit.laurel's sync no longer writes `~/.agents/skills`, so
    # that root is empty and this is the only one with content.
    skills = [ "~/.claude/skills" ];

    # Hide the startup header. It listed every theme, skill, and MCP server on each
    # session start, which is a catalogue of what is installed rather than anything
    # about the session, and the sidebar reports the session state that matters.
    # `--verbose` still forces it back for one run when something needs diagnosing.
    quietStartup = true;

    # nvim-pi is a --clean nvim wrapper, so Ctrl+G opens instantly instead of
    # setting was undeclared and the keybinding was unbound, which made the
    # binary unreachable by either route.
    externalEditor = "${lib.getExe nvimPi}";
    # Nix owns every harness update in this repository, so the install ping is
    # off. This does not disable pi's version check; PI_SKIP_VERSION_CHECK does.
    enableInstallTelemetry = false;

    # Read from its own file so the `pi-shell-prefix-loads-aliases` flake check can
    # RUN it. The runtime-written value once carried a literal backslash-n, which
    # made the whole prefix one unparseable line and loaded no alias.
    shellCommandPrefix = builtins.readFile ./shell-prefix.sh;
  };

  # which the installed build does not recognize. The activation merge is a deep
  # merge, so undeclaring one leaves it on disk forever; only an explicit delete
  # removes it.
  #
  inherit (piKeys) retired;
  piRetiredSettings = retired;

  # Keys this module once declared and has since handed back to the owner. They
  # are NOT retired: retiring would delete the owner's runtime choice on every
  # activation. They are listed so the handback is a recorded decision rather
  # than an edit someone has to reconstruct from git history.
  piOwnerPreferenceKeys = piKeys.ownerPreference;

  # A key cannot be both declared and handed back.
  piPreferenceOverlap = lib.intersectLists piDeclaredKeys piOwnerPreferenceKeys;
  assertPreferencesUndeclared =
    if piPreferenceOverlap != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " piPreferenceOverlap} is declared but listed as owner preference. Declaring it reverts the owner's runtime choice on every activation."
    else
      true;

  # Every declared key must exist in the build that reads it. A key absent from
  # the binary is dead configuration that reads as a working setting.
  piDeclaredKeys = builtins.attrNames piManagedSettings;

  # A generated theme nobody selects is a file pi never reads. Structural, not
  # tautological: the setting, the theme's own `name` field, and the install
  # filename all derive from `piThemeName`, so this compares the setting against
  # the one definition rather than against a second copy of the same literal.
  stylixTheme = builtins.toJSON stylixThemeAttrs;

  assertThemeSelected =
    if (piManagedSettings.theme or "") != piThemeName then
      throw "pi.nix: the ${piThemeName} theme is generated and installed but `piManagedSettings.theme` does not select it."
    else if (stylixThemeAttrs.name or "") != piThemeName then
      throw "pi.nix: the generated theme names itself '${stylixThemeAttrs.name or ""}' but the setting selects '${piThemeName}'. Pi resolves a theme by its name field, so the theme would be installed and unselected."
    else
      true;

  # The rendered settings must match the declared list exactly, in both
  # directions. Otherwise the flake check verifies a list that is not what the
  # module actually writes.
  keysNotDeclared = lib.subtractLists piKeys.declared piDeclaredKeys;
  keysNotRendered = lib.subtractLists piDeclaredKeys piKeys.declared;
  assertKeysMatchManifest =
    if keysNotDeclared != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " keysNotDeclared} is written to settings.json but missing from settings-keys.nix, so nothing verifies it against the installed binary."
    else if keysNotRendered != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " keysNotRendered} is listed in settings-keys.nix but not written to settings.json. Remove the stale entry."
    else
      true;

  piKeyOverlap = lib.intersectLists piDeclaredKeys piRetiredSettings;
  assertPiKeysDisjoint =
    if piKeyOverlap != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " piKeyOverlap} is both declared and retired; activation would delete it and then merge it back on every switch."
    else
      true;

  piKeybindings = pkgs.writeText "pi-keybindings.json" (
    builtins.toJSON {
      # Namespaced ids, per the installed build's docs/keybindings.json format.
      # `renameSession` was the pre-namespace id. The docs describe an automatic
      # migration, but the pinned 0.82.1 binary contains that literal string zero
      # times, so the binding was silently INERT rather than migrated: ctrl+shift+r
      # did nothing. Measured, not inferred.
      #
      # Rename moves off its `ctrl+r` default because pi-readline-search binds
      # ctrl+r for reverse history search.
      "app.session.rename" = "ctrl+shift+r";
      # `left` only, dropping the `ctrl+b` half of the default. diff-review.ts
      # registers ctrl+b for the neovim review split, and which of the two wins is
      # a precedence question that is better removed than relied on.
      "tui.editor.cursorLeft" = "left";
    }
  );

  # Also on PATH, so the owner can refresh both configs without a switch after pi
  # discovers a new model.
  piOpenaiModels = pkgs.writeShellApplication {
    name = "pi-openai-model-configs";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ./openai-model-configs.sh;
  };

in
{
  # Pi rewrites settings.json at runtime (session bookkeeping,
  # `lastChangelogVersion`), so it cannot be a store symlink. Anything absent
  # from `piManagedSettings` is left to pi's own runtime.
  sysinit.llm.managedFiles.pi = {
    path = ".pi/agent/settings.json";
    format = "json";
    content = piManagedSettings;
    retire = piRetiredSettings;
    # Every declared key, not just the two lists. D2 in design.md defines a
    # declared key as one whose value is repository policy, and `enforce` is the
    # only mechanism in managed-file.nix that makes Nix win on EVERY activation.
    #
    # Without this, the three-way merge returns the disk value whenever the Nix
    # value has not changed since the base (`$n == $b` at lib/managed-file.nix:25),
    # so a declared key wins exactly once and never again. Measured: base
    # `theme=stylix`, disk `theme=dark`, new `theme=stylix` merged to `dark`, which
    # is the "stylix theme is never selected" defect the proposal exists to fix,
    # reappearing on the first pi-side theme write.
    #
    # `packages` and `skills` were already here for a second reason that still
    # holds: a list is compared whole, so leaving them mergeable turns any pi-side
    # edit into a blocking conflict.
    #
    # Latent, and safe today: `enforce` replaces a block wholesale, so a NESTED
    # declared key would discard whatever pi wrote inside it. Every declared key is
    # currently a scalar or a flat list, so nothing is lost. Declaring a nested block
    # here means deciding whether Nix owns every leaf under it.
    enforce = piKeys.declared;
  };

  # Both @benvargas/pi-openai-* configs carry a list of model ids, so neither is
  # declared here. A model list in Nix goes stale exactly the way the extensions'
  # own hardcoded defaults did, and costs a commit per model. piOpenaiModels
  # regenerates both from pi's live catalog instead; see the script for why.
  #
  # Ordered after linkGeneration, unlike the reconciler: an earlier generation may
  # have left a store symlink at either path, and cleanup has to remove it before
  # the script writes a real file there.
  home.activation.piOpenaiModelConfigs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${lib.getExe piOpenaiModels} || \
      echo "pi-openai-models: left the openai model configs untouched; see above. Activation continued." >&2
  '';

  home = {
    packages = [
      piAcp
      piCosts
      nvimPi
      piOpenaiModels
    ];

    file =
      (
        assert assertExtensionsExist;
        assert assertPiBridgeInstalled;
        assert assertGeminiAuthEntrypoint;
        assert assertGatesDisjoint;
        assert assertPiKeysDisjoint;
        assert assertThemeSelected;
        assert assertPreferencesUndeclared;
        assert assertKeysMatchManifest;
        assert assertContextHookOrder;
        extensionFiles
      )
      // customExtensionFiles
      // {
        ".pi/agent/keybindings.json" = {
          source = piKeybindings;
          force = true;
        };
        # pi-vcc: take over Pi's native compaction path deterministically.
        ".pi/agent/pi-vcc-config.json" = {
          text = builtins.toJSON {
            overrideDefaultCompaction = true;
          };
          force = true;
        };
        # Pi reads a global context file here, per its bundled docs/usage.md.
        # Nothing wrote it, so pi ran without the shared conventions, the
        # prohibitions, or the output style that every other harness gets.
        ".pi/agent/AGENTS.md" = {
          text = kit.mkInstructionsWithStyle {
            harness = "pi";
            skillsRoot = "~/.claude/skills";
          };
          force = true;
        };
        ".pi/agent/themes/${piThemeName}.json" = {
          text = stylixTheme;
          force = true;
        };
        # pi's permission gate, rendered from the SAME lib/allowlist.nix every other
        # harness reads. Before this it was a hand-written file carrying
        # `yoloMode: true`, which auto-approved every ask-state check, so pi was the
        # one harness with no gate at all and the allowlist tiers reached it not.
        #
        # `yoloMode = false` is the substantive change here: commands outside the
        # tiers now prompt instead of running. That is the point, and it is the one
        # setting to flip back if a prompt storm gets in the way.
        ".pi/agent/extensions/pi-permission-system/config.json" = {
          text = builtins.toJSON {
            debugLog = false;
            permissionReviewLog = true;
            inherit yoloMode;
            permission = llmLib.allowlist.formatForPi {
              allowTiers = llmLib.allowlist.tierA ++ llmLib.allowlist.tierB;
              denyGlobs = llmLib.allowlist.destructiveDenyGlobs;
              mcpTier = llmLib.allowlist.tierMcp;
              yolo = yoloMode;
            };
          };
          force = true;
        };

        # Disable write/edit overrides in pi-tool-display so pi-diff owns them.
        ".pi/agent/extensions/pi-tool-display/config.json" = {
          text = builtins.toJSON {
            registerToolOverrides = {
              read = true;
              grep = true;
              find = true;
              ls = true;
              bash = true;
              edit = false;
              write = false;
            };
          };
          force = true;
        };
      };

    sessionVariables = {
      PI_SKIP_VERSION_CHECK = "$HOME/.pi";
    };
  };
}
