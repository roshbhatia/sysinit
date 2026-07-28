{ config, lib, ... }:

let
  cfg = config.sysinit.darwin.keybindings;
  user = lib.escapeShellArg config.system.primaryUser;

  disabled = {
    enable = false;
  };

  hotkey = enable: char: code: mods: {
    inherit enable;
    keys = [
      char
      code
      mods
    ];
  };

  # `defaults write` replaces the whole AppleSymbolicHotKeys dict, so this set
  # has to stay complete. aerospace owns tiling and space switching, raycast
  # owns cmd+space, so almost every macOS window and search shortcut is off.
  baseSymbolicHotkeys = {
    "7" = hotkey false 65535 120 8650752;
    "8" = hotkey false 65535 99 8650752;
    "9" = hotkey false 65535 118 8650752;
    "10" = hotkey false 65535 96 8650752;
    "11" = hotkey false 65535 97 8650752;
    "12" = hotkey false 65535 122 8650752;
    "13" = hotkey false 65535 98 8650752;
    "15" = disabled;
    "16" = disabled;
    "17" = disabled;
    "18" = disabled;
    "19" = disabled;
    "20" = disabled;
    "21" = disabled;
    "22" = disabled;
    "23" = disabled;
    "24" = disabled;
    "25" = disabled;
    "26" = disabled;
    # cmd+` move focus to next window
    "27" = hotkey false 96 50 1048576;
    # ctrl+up mission control, ctrl+down application windows
    "32" = hotkey false 65535 126 8650752;
    "33" = hotkey false 65535 125 8650752;
    "36" = hotkey false 65535 103 8388608;
    "52" = hotkey false 100 2 1572864;
    "53" = hotkey false 65535 107 8388608;
    "54" = hotkey false 65535 113 8388608;
    "57" = hotkey false 65535 100 8650752;
    "59" = hotkey false 65535 96 9437184;
    # ctrl+space and ctrl+opt+space input source switching
    "60" = hotkey false 32 49 262144;
    "61" = hotkey false 32 49 786432;
    # cmd+space spotlight, cmd+opt+space spotlight finder window
    "64" = hotkey false 32 49 1048576;
    "65" = hotkey false 32 49 1572864;
    # ctrl+arrow space switching off, ctrl+shift+arrow on
    "79" = hotkey false 65535 123 8650752;
    "80" = hotkey true 65535 123 8781824;
    "81" = hotkey false 65535 124 8650752;
    "82" = hotkey true 65535 124 8781824;
    "98" = hotkey false 47 44 1179648;
    "118" = hotkey false 65535 18 262144;
    "159" = hotkey false 65535 36 262144;
    "162" = hotkey false 65535 96 9961472;
    "164" = hotkey false 65535 65535 0;
    "175" = hotkey false 65535 65535 0;
    "190" = hotkey false 113 12 8388608;
    "215" = hotkey false 65535 65535 0;
    "216" = hotkey false 65535 65535 0;
    "217" = hotkey false 65535 65535 0;
    "218" = hotkey false 65535 65535 0;
    "219" = hotkey false 65535 65535 0;
    "222" = hotkey false 65535 65535 0;
    "223" = hotkey false 65535 65535 0;
    "224" = hotkey false 65535 65535 0;
    "225" = hotkey false 65535 65535 0;
    "226" = hotkey false 65535 65535 0;
    "227" = hotkey false 65535 65535 0;
    "228" = hotkey false 65535 65535 0;
    "229" = hotkey false 65535 65535 0;
    "230" = hotkey false 65535 65535 0;
    "231" = hotkey false 65535 65535 0;
    "232" = hotkey false 65535 65535 0;
    "233" = hotkey true 109 46 1048576;
    "235" = hotkey false 65535 65535 0;
    # 237-251: Sequoia window tiling, all off so aerospace owns tiling
    "237" = hotkey false 102 3 8650752;
    "238" = hotkey false 99 8 8650752;
    "239" = hotkey false 114 15 8650752;
    "240" = hotkey false 65535 123 8650752;
    "241" = hotkey false 65535 124 8650752;
    "242" = hotkey false 65535 126 8650752;
    "243" = hotkey false 65535 125 8650752;
    "244" = hotkey false 65535 65535 0;
    "245" = hotkey false 65535 65535 0;
    "246" = hotkey false 65535 65535 0;
    "247" = hotkey false 65535 65535 0;
    "248" = hotkey false 65535 123 8781824;
    "249" = hotkey false 65535 124 8781824;
    "250" = hotkey false 65535 126 8781824;
    "251" = hotkey false 65535 125 8781824;
    "256" = hotkey false 65535 65535 0;
    "257" = hotkey false 65535 65535 0;
    "258" = hotkey false 65535 65535 0;
    "260" = hotkey false 65535 53 1048576;
  };

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

  # A chord is compared as "<mods in fixed order>+<key>". macOS sets the fn bit
  # on arrows and function keys and no other layer encodes it, so fn is left out
  # or an arrow hotkey would never match a hand-written "ctrl+shift+left".
  modNames = [
    {
      bit = 1048576;
      name = "cmd";
    }
    {
      bit = 262144;
      name = "ctrl";
    }
    {
      bit = 524288;
      name = "alt";
    }
    {
      bit = 131072;
      name = "shift";
    }
  ];

  keyNames = {
    "2" = "d";
    "3" = "f";
    "8" = "c";
    "12" = "q";
    "15" = "r";
    "18" = "1";
    "36" = "enter";
    "44" = "slash";
    "46" = "m";
    "48" = "tab";
    "49" = "space";
    "50" = "grave";
    "53" = "escape";
    "96" = "f5";
    "97" = "f6";
    "98" = "f7";
    "99" = "f3";
    "100" = "f8";
    "103" = "f11";
    "107" = "f14";
    "113" = "f15";
    "118" = "f4";
    "120" = "f2";
    "123" = "left";
    "124" = "right";
    "125" = "down";
    "126" = "up";
  };

  # aerospace spells the same keys differently; fold both onto one vocabulary.
  keyAliases = {
    esc = "escape";
    "/" = "slash";
    "`" = "grave";
  };
  canonicalKey = k: keyAliases.${k} or k;

  mkChord = mods: key: lib.concatStringsSep "+" ((map (m: m.name) mods) ++ [ (canonicalKey key) ]);

  chordOfHotkey =
    keys:
    let
      code = builtins.elemAt keys 1;
      bits = builtins.elemAt keys 2;
      present = lib.filter (m: lib.bitAnd bits m.bit != 0) modNames;
    in
    mkChord present (keyNames.${toString code} or "kc${toString code}");

  # aerospace binding names look like "alt-shift-1"; the last token is the key.
  chordOfBindingName =
    name:
    let
      parts = lib.splitString "-" name;
      given = lib.init parts;
      present = lib.filter (m: lib.elem m.name given) modNames;
    in
    mkChord present (lib.last parts);

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
  sysinit.darwin.keybindings.symbolicHotkeys = baseSymbolicHotkeys;

  # Global chords held by layers that live outside Nix-readable config: raycast's
  # own store, an Electron settings file, and hammerspoon lua.
  sysinit.darwin.keybindings.reservedChords = {
    "cmd+space" = "raycast";
    "cmd+tab" = "hammerspoon window switcher";
    "cmd+shift+tab" = "hammerspoon window switcher";
    "cmd+]" = "hammerspoon vim-mode";
    "cmd+enter" = "claude desktop quick entry";
    "cmd+shift+enter" = "claude desktop quick entry dictation";
    "cmd+alt+enter" = "goose desktop quick launcher";
  };

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
      assertion = aerospaceHits == [ ];
      message = "sysinit.darwin.keybindings: aerospace binding collides with a reserved chord or an enabled symbolic hotkey: ${lib.concatStringsSep ", " aerospaceHits}";
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
