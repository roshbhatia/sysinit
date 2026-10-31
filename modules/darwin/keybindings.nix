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

  enabledHotkeys = lib.mapAttrsToList (id: hotkey: {
    inherit id;
    chord = chords.chordOfHotkey hotkey.keys;
  }) (lib.filterAttrs (_: hotkey: hotkey.enable && hotkey.keys != null) cfg.symbolicHotkeys);

  sharedChords = lib.filterAttrs (_: entries: builtins.length entries > 1) (
    lib.groupBy (entry: entry.chord) enabledHotkeys
  );

  reservedHits = lib.filter (entry: builtins.hasAttr entry.chord cfg.reservedChords) enabledHotkeys;

  riftSettings = lib.attrByPath [ "sysinit" "darwin" "rift" "settings" ] { } config;
  riftMaps = [
    (riftSettings.keys or { })
  ]
  ++ builtins.attrValues (riftSettings.binding_modes or { });
  riftChordOfBindingName =
    name:
    let
      parts = map lib.toLower (lib.splitString " + " name);
      modifiers = {
        alt = "alt";
        cmd = "cmd";
        command = "cmd";
        control = "ctrl";
        ctrl = "ctrl";
        meta = "cmd";
        shift = "shift";
      };
      present = lib.filter (part: builtins.hasAttr part modifiers) parts;
    in
    lib.concatStringsSep "+" (
      (map (part: modifiers.${part}) present) ++ [ (chords.canonicalKey (lib.last parts)) ]
    );
  riftChords = lib.unique (
    lib.concatMap (bindings: map riftChordOfBindingName (builtins.attrNames bindings)) riftMaps
  );
  riftHits = lib.filter (
    chord:
    builtins.hasAttr chord cfg.reservedChords || lib.any (entry: entry.chord == chord) enabledHotkeys
  ) riftChords;

  describeHotkeys = lib.concatMapStringsSep ", " (entry: "${entry.chord} (ID ${entry.id})");
in
{
  sysinit.darwin.keybindings.symbolicHotkeys = chords.baseSymbolicHotkeys;
  sysinit.darwin.keybindings.reservedChords = chords.reservedChords;

  assertions = [
    {
      assertion = sharedChords == { };
      message = "sysinit.darwin.keybindings: enabled symbolic hotkeys share a chord: ${
        lib.concatStringsSep "; " (
          lib.mapAttrsToList (
            chord: entries: "${chord} <- IDs ${lib.concatMapStringsSep "/" (entry: entry.id) entries}"
          ) sharedChords
        )
      }";
    }
    {
      assertion = reservedHits == [ ];
      message = "sysinit.darwin.keybindings: enabled symbolic hotkey collides with a reserved chord: ${describeHotkeys reservedHits}";
    }
    {
      assertion = riftHits == [ ];
      message = "sysinit.darwin.keybindings: Rift binding collides with a reserved or symbolic chord: ${lib.concatStringsSep ", " riftHits}";
    }
  ];

  system.defaults.CustomUserPreferences = lib.recursiveUpdate appShortcutPrefs hotkeyPrefs;

  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
      || true
  '';
}
