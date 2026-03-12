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

  piPackages = [
    "git:github.com/Gurpartap/pi-mermaid"
    "git:github.com/omaclaren/pi-annotated-reply" # Cite sources
    "git:github.com/ttttmr/pi-context" # Auto inject context
    "npm:pi-dcp" # Dynamic context pruning
    "npm:pi-readline-search" # CTRL-r like in my shell
    "npm:pi-rtk"
    "npm:pi-subagents"
    "npm:pi-threads" # History search skill?
    "npm:pi-vim"
    "npm:pi-webfetch-to-markdown"
  ];

  installPiPackages = pkgs.writeShellScript "install-pi-packages" ''
    export PATH="${pkgs.git}/bin:${pkgs.bun}/bin:${pkgs.nodejs}/bin:${pkgs.openssh}/bin:$PATH"
    export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_personal -o IdentitiesOnly=yes"

    SETTINGS="$HOME/.pi/agent/settings.json"
    PI="${pkgs.pi-coding-agent}/bin/pi"

    for pkg in ${lib.escapeShellArgs piPackages}; do
      if ! grep -qF "$pkg" "$SETTINGS" 2>/dev/null; then
        echo "Installing pi package: $pkg"
        "$PI" install "$pkg" || echo "Warning: failed to install $pkg"
      fi
    done

    npm install -g pi-acp || echo "Warning: failed to install pi-acp"
  '';
in
{
  home = {
    activation.piPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${installPiPackages}
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
          };
          force = true;
        };
      };

    sessionVariables = {
      PI_SKIP_VERSION_CHECK = "$HOME/.pi";
    };
  };
}
