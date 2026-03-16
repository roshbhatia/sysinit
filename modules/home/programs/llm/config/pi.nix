{
  lib,
  pkgs,
  config,
  ...
}:
let
  piExtensionsRev = "85d06052fbee06c87533931febcf68a81f2b0c7a";
  piExtensionsSrc = pkgs.fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    rev = piExtensionsRev;
    sha256 = "1lj0vrx5yvf71sqai4zqk1idgnrqzcimg4mmlicg7091jsp12qsk";
  };
  extensionsDir = "${piExtensionsSrc}/packages/coding-agent/examples/extensions";
  subagents = import ../subagents;
  agentNames = builtins.filter (k: k != "formatSubagentAsMarkdown") (builtins.attrNames subagents);

  extensions = [
    "confirm-destructive"
    "dirty-repo-guard"
    "git-checkpoint"
    "handoff"
    "interactive-shell"
    "notify"
    "session-name"
    "status-line"
    "tools"
  ];

  extensionFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".pi/agent/extensions/${name}.ts" {
        source = "${extensionsDir}/${name}.ts";
        force = true;
      }
    ) extensions
  );

  # User-level agents generated from modules/home/programs/llm/subagents/*.nix.
  # Add a new .nix file there and register it in subagents/default.nix to define an agent.
  agentFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".pi/agent/agents/${name}.md" {
        text = subagents.formatSubagentAsMarkdown {
          inherit name;
          config = subagents.${name};
        };
        force = true;
      }
    ) agentNames
  );

  stylixTheme =
    let
      c = config.lib.stylix.colors;
      hex = name: "#${c.${name}}";
    in
    builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
      name = "stylix";
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
  # npm deps) or a buildNpmPackage derivation (runtime deps needed at load time).
  # ---------------------------------------------------------------------------

  # Helper: fetch an npm package tarball from the registry and extract it.
  # npm tarballs have a top-level "package/" dir; fetchzip strips it so
  # the derivation root contains package.json directly.
  fetchNpmPkg =
    {
      name,
      version,
      hash,
    }:
    pkgs.fetchzip {
      url = "https://registry.npmjs.org/${name}/-/${name}-${version}.tgz";
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

  # Git packages - source only (no runtime npm deps)
  piPkgAnnotatedReply = pkgs.fetchFromGitHub {
    owner = "omaclaren";
    repo = "pi-annotated-reply";
    rev = "a230173eec2f3375671eb306b8749662b0ac9122";
    hash = "sha256-BiwaJB1XrWsAuYXVrRTtpYZdIRD24KPxCfroAXiA02c=";
  };

  piPkgContext = pkgs.fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "7fd8752d05d98e4e38a7d0bc22de51d72d99f398";
    hash = "sha256-cbcXUSzZfAXupQ1fzsise4OXFwH1N2VAIA3jdDyLJ/U=";
  };

  # Git package with runtime npm deps - package-lock.json is in the repo
  piPkgMermaid = pkgs.buildNpmPackage {
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
  piPkgVim = fetchNpmPkg {
    name = "pi-vim";
    version = "0.1.8";
    hash = "sha256-CYkELMs7mbTAthmijkPir/jIg/3Cl6jmkKfk6RhV3iE=";
  };
  piPkgSubagents = fetchNpmPkg {
    name = "pi-subagents";
    version = "0.11.2";
    hash = "sha256-IpZ1sILJP5zWIQ63C+vR7L4CeWdBu8dfkm+k2p+kzRI=";
  };
  piPkgReadlineSearch = fetchNpmPkg {
    name = "pi-readline-search";
    version = "0.1.0";
    hash = "sha256-HxomHcIceZX68M0f0ZcRJSiqDzqCI0p+wcyq8CVL514=";
  };
  piPkgRtk = fetchNpmPkg {
    name = "pi-rtk";
    version = "0.1.4";
    hash = "sha256-2UaCeGo5IadpVywZHzh3D1RQ7L+CGjGg+aMWlJUxW14=";
  };
  piPkgThreads = fetchNpmPkg {
    name = "pi-threads";
    version = "0.2.1";
    hash = "sha256-MF++ANxMplxx0qydKoozrnNTFtb4HQ/0s923cGrsPyM=";
  };

  # npm packages with runtime deps - lock files stored in ./locks/
  piPkgDcp = buildNpmPkg {
    name = "pi-dcp";
    version = "0.2.0";
    hash = "sha256-mQ+F/0EoH8WKvY4Nq5vPnOhQWHNBTd7PmVDHmEfOfOQ=";
    npmDepsHash = "sha256-YyuGS17egfLwhqOwfYUKV7YY6Je9lS60HRUzBBBtoS8=";
    lockFile = ./locks/pi-dcp.lock.json;
  };
  piPkgWebfetch = buildNpmPkg {
    name = "pi-webfetch-to-markdown";
    version = "1.0.1";
    hash = "sha256-48W7utsKPZky3W5Xe9bB9g9Wp9lcQVWteZwsEYtmQ7k=";
    npmDepsHash = "sha256-vjBFvarCqnv80YoWck0MnAXScWe4l8xP/qSBZ6kmWJY=";
    lockFile = ./locks/pi-webfetch-to-markdown.lock.json;
  };

  # pi-acp is a standalone CLI tool (not a pi package) - exposed via home.packages.
  # dist/ is pre-compiled in the npm tarball; --ignore-scripts prevents npm ci
  # from triggering the prepare lifecycle hook (which would try to run tsup).
  piAcp = pkgs.buildNpmPackage {
    pname = "pi-acp";
    version = "0.0.22";
    src = fetchNpmPkg {
      name = "pi-acp";
      version = "0.0.22";
      hash = "sha256-2Sa0mUUzBtt4ehnb78uHx4p5COf89ZZ8tilQ06z7BJM=";
    };
    postPatch = ''
      cp ${./locks/pi-acp.lock.json} package-lock.json
    '';
    npmDepsHash = "sha256-D7u7+MeA92PChDC9UC4es/bUJvaaRHBMldqcj2wiO6U=";
    npmFlags = "--ignore-scripts";
    dontNpmBuild = true;
  };

  # JSON file written to the Nix store containing the local-path package list.
  # The activation script reads this and merges it into settings.json so that
  # pi discovers the store-local packages on startup without any network access.
  piPackagesJson = pkgs.writeText "pi-packages.json" (
    builtins.toJSON [
      "${piPkgAnnotatedReply}"
      "${piPkgContext}"
      "${piPkgMermaid}"
      "${piPkgVim}"
      "${piPkgSubagents}"
      "${piPkgReadlineSearch}"
      "${piPkgRtk}"
      "${piPkgThreads}"
      "${piPkgDcp}"
      "${piPkgWebfetch}"
    ]
  );

  updatePiSettings = pkgs.writeShellScript "update-pi-settings" ''
    SETTINGS="$HOME/.pi/agent/settings.json"
    PACKAGES=$(cat ${piPackagesJson})

    if [ -f "$SETTINGS" ]; then
      ${pkgs.jq}/bin/jq \
        --argjson pkgs "$PACKAGES" \
        '. + {packages: $pkgs}' \
        "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    else
      mkdir -p "$(dirname "$SETTINGS")"
      ${pkgs.jq}/bin/jq -n \
        --argjson pkgs "$PACKAGES" \
        --arg prefix "$SHELL_PREFIX" \
        '{packages: $pkgs}' > "$SETTINGS"
    fi
  '';
in
{
  home = {
    packages = [ piAcp ];

    activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${updatePiSettings}
    '';

    file =
      extensionFiles
      // agentFiles
      // {
        ".pi/agent/themes/stylix.json" = {
          text = stylixTheme;
          force = true;
        };
        ".pi/agent/keybindings.json" = {
          text = builtins.toJSON {
            renameSession = "ctrl+shift+r";
            externalEditor = "ctrl+e";
          };
          force = true;
        };
      };

    sessionVariables = {
      PI_SKIP_VERSION_CHECK = "$HOME/.pi";
    };
  };
}
