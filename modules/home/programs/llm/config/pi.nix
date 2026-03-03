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

  extensions = [
    "confirm-destructive"
    "dirty-repo-guard"
    "git-checkpoint"
    "handoff"
    "modal-editor"
    "notify"
    "questionnaire"
    "session-name"
    "status-line"
    "tools"
  ];

  extensionFiles = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/extensions/${name}.ts";
      value = {
        source = "${extensionsDir}/${name}.ts";
        force = true;
      };
    }) extensions
  );

  # Stylix base16 theme for pi - maps base16 palette to pi's 51 color tokens
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

  themeFile = lib.mkIf (config.stylix.enable or false) {
    ".pi/agent/themes/stylix.json" = {
      text = stylixTheme;
      force = true;
    };
  };
in
{
  home.file = extensionFiles // themeFile;
}
