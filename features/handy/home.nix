{
  config,
  lib,
  pkgs,
  ...
}:

let
  shortcuts = import ./shortcuts.nix;
in
{
  options.sysinit.handy.customWords = lib.mkOption {
    type = lib.types.listOf lib.types.nonEmptyStr;
    default = [ ];
    description = "Words and phrases supplied to Handy's native transcription dictionary.";
  };

  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    sysinit.handy.customWords = import ./vocabulary.nix;

    sysinit.llm.managedFiles.handy = {
      path = "Library/Application Support/com.pais.handy/settings_store.json";
      capture = false;
      format = "json";
      createIfMissing = false;
      content.settings = {
        custom_words = lib.unique config.sysinit.handy.customWords;
        bindings = lib.mapAttrs (_: chord: {
          current_binding = lib.replaceStrings [ "cmd" "alt" ] [ "command" "option" ] chord;
        }) shortcuts;
      };
      enforce = [
        [
          "settings"
          "custom_words"
        ]
      ]
      ++ map (name: [
        "settings"
        "bindings"
        name
        "current_binding"
      ]) (builtins.attrNames shortcuts);
    };
  };
}
