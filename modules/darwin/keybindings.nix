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
in
{
  sysinit.darwin.keybindings.symbolicHotkeys = baseSymbolicHotkeys;

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
