{ config, lib, ... }:

let
  cfg = config.sysinit.darwin.keybindings;
  user = lib.escapeShellArg config.system.primaryUser;

  renderHotkey =
    _: hk:
    {
      enabled = if hk.enable then 1 else 0;
    }
    // lib.optionalAttrs (hk.keys != null) {
      value = {
        parameters = hk.keys;
        type = "standard";
      };
    };

  appShortcutPrefs = lib.mapAttrs (_: shortcuts: {
    NSUserKeyEquivalents = shortcuts;
  }) cfg.appShortcuts;

  hotkeyPrefs = {
    "com.apple.symbolichotkeys".AppleSymbolicHotKeys = lib.mapAttrs renderHotkey cfg.symbolicHotkeys;
  };

  chords = import ./lib/chords.nix { inherit lib; };
  inherit (chords) chordOfHotkey chordOfBindingName;

  enabledHotkeys = lib.mapAttrsToList (id: hk: {
    inherit id;
    chord = chordOfHotkey hk.keys;
  }) (lib.filterAttrs (_: hk: hk.enable && hk.keys != null) cfg.symbolicHotkeys);

  sharedChords = lib.filterAttrs (_: es: builtins.length es > 1) (
    lib.groupBy (e: e.chord) enabledHotkeys
  );

  reservedHits = lib.filter (e: cfg.reservedChords ? ${e.chord}) enabledHotkeys;

  aerospaceModes = lib.attrByPath [ "services" "aerospace" "settings" "mode" ] { } config;
  aerospaceChords = lib.unique (
    lib.concatMap (m: map chordOfBindingName (builtins.attrNames (m.binding or { }))) (
      builtins.attrValues aerospaceModes
    )
  );
  aerospaceHits = lib.filter (
    c: (cfg.reservedChords ? ${c}) || lib.any (e: e.chord == c) enabledHotkeys
  ) aerospaceChords;

  describe = es: lib.concatMapStringsSep ", " (e: "${e.chord} (ID ${e.id})") es;
in
{
  sysinit.darwin.keybindings.symbolicHotkeys = chords.baseSymbolicHotkeys;

  sysinit.darwin.keybindings.reservedChords = chords.reservedChords;

  assertions = [
    {
      assertion = sharedChords == { };
      message = "sysinit.darwin.keybindings: two enabled symbolic hotkeys claim one chord: ${
        lib.concatStringsSep "; " (
          lib.mapAttrsToList (
            chord: es: "${chord} <- IDs ${lib.concatMapStringsSep "/" (e: e.id) es}"
          ) sharedChords
        )
      }";
    }
    {
      assertion = reservedHits == [ ];
      message = "sysinit.darwin.keybindings: enabled symbolic hotkey collides with a reserved chord: ${describe reservedHits}";
    }
    {
      assertion = aerospaceHits == [ ];
      message = "sysinit.darwin.keybindings: aerospace binding collides with a reserved chord or an enabled symbolic hotkey: ${lib.concatStringsSep ", " aerospaceHits}";
    }
  ];

  system.defaults.CustomUserPreferences = lib.recursiveUpdate appShortcutPrefs hotkeyPrefs;

  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
      || true
  '';
}
