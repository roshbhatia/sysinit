{ config, lib, ... }:

let
  cfg = config.sysinit.darwin.keybindings;
  user = lib.escapeShellArg config.system.primaryUser;

  # `defaults write` replaces the whole AppleSymbolicHotKeys dict, so this set
  # has to stay complete. aerospork owns tiling and space switching, raycast
  # owns cmd+space, so almost every macOS window and search shortcut is off.

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

  # Chord vocabulary lives in ./lib/chords.nix so the `wezterm-chord-collisions`
  # flake check canonicalizes chords the same way this assertion does.
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

  aerosporkModes = lib.attrByPath [ "services" "aerospork" "settings" "mode" ] { } config;
  aerosporkChords = lib.unique (
    lib.concatMap (m: map chordOfBindingName (builtins.attrNames (m.binding or { }))) (
      builtins.attrValues aerosporkModes
    )
  );
  aerosporkHits = lib.filter (
    c: (cfg.reservedChords ? ${c}) || lib.any (e: e.chord == c) enabledHotkeys
  ) aerosporkChords;

  describe = es: lib.concatMapStringsSep ", " (e: "${e.chord} (ID ${e.id})") es;
in
{
  sysinit.darwin.keybindings.symbolicHotkeys = chords.baseSymbolicHotkeys;

  # Global chords held by layers outside Nix-readable config (raycast's own
  # store, an Electron settings file, hammerspoon lua). Declared in
  # ./lib/chords.nix so the wezterm chord check reads the same list.
  sysinit.darwin.keybindings.reservedChords = chords.reservedChords;

  # Nothing detects a chord fight at runtime: whichever layer registers first
  # wins and the other silently never fires, which is how hammerspoon's cmd+]
  # swallowed WezTerm's workspace cycle. Catch it at eval instead.
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
      assertion = aerosporkHits == [ ];
      message = "sysinit.darwin.keybindings: aerospork binding collides with a reserved chord or an enabled symbolic hotkey: ${lib.concatStringsSep ", " aerosporkHits}";
    }
  ];

  system.defaults.CustomUserPreferences = lib.recursiveUpdate appShortcutPrefs hotkeyPrefs;

  # nix-darwin no longer nudges the settings daemon, so a fresh symbolic hotkey
  # would otherwise wait for the next logout. Activation runs as root, and
  # activateSettings only reloads the calling user's session, so drop into the
  # primary user's GUI session the same way nix-darwin writes user defaults.
  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
      || true
  '';
}
