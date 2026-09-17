{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.system.defaults;
  entry = domain: values: [
    domain
    (lib.filterAttrs (_: value: value != null) values)
  ];
  removals = lib.mapAttrsToList (domain: keys: [
    domain
    (lib.genAttrs keys (_: null))
  ]) config.sysinit.darwin.defaults.remove;
  users = [
    (entry ".GlobalPreferences" cfg.NSGlobalDomain)
    (entry ".GlobalPreferences" cfg.".GlobalPreferences")
    (entry "com.apple.LaunchServices" cfg.LaunchServices)
    (entry "com.apple.menuextra.clock" cfg.menuExtraClock)
    (entry "com.apple.dock" (builtins.removeAttrs cfg.dock [ "expose-group-by-app" ]))
    (entry "com.apple.finder" cfg.finder)
    (entry "com.apple.HIToolbox" cfg.hitoolbox)
    (entry "com.apple.iCal" cfg.iCal)
    (entry "com.apple.AppleMultitouchMouse" cfg.magicmouse)
    (entry "com.apple.driver.AppleMultitouchMouse.mouse" cfg.magicmouse)
    (entry "com.apple.screencapture" cfg.screencapture)
    (entry "com.apple.screensaver" cfg.screensaver)
    (entry "com.apple.spaces" cfg.spaces)
    (entry "com.apple.AppleMultitouchTrackpad" cfg.trackpad)
    (entry "com.apple.driver.AppleBluetoothMultitouch.trackpad" cfg.trackpad)
    (entry "com.apple.universalaccess" cfg.universalaccess)
    (entry "com.apple.ActivityMonitor" cfg.ActivityMonitor)
  ]
  ++ removals
  ++ lib.mapAttrsToList entry cfg.CustomUserPreferences
  ++ [
    (entry "com.apple.WindowManager" cfg.WindowManager)
    (entry "~${config.system.primaryUser}/Library/Preferences/ByHost/com.apple.controlcenter" cfg.controlcenter)
  ];
  systems = [
    (entry "/Library/Preferences/com.apple.loginwindow" cfg.loginwindow)
    (entry "/Library/Preferences/SystemConfiguration/com.apple.smb.server" cfg.smb)
    (entry "/Library/Preferences/com.apple.SoftwareUpdate" cfg.SoftwareUpdate)
  ]
  ++ lib.mapAttrsToList entry cfg.CustomSystemPreferences;
  render =
    name: entries:
    pkgs.writeText name (
      builtins.toJSON (builtins.filter (item: builtins.elemAt item 1 != { }) entries)
    );
  runner = "${lib.getExe pkgs.python3} ${./defaults-incremental.py}";
in
{
  assertions = [
    {
      assertion = builtins.all (
        name:
        builtins.elem name [
          "alf" # Removed options retained by nix-darwin for migration errors.
          "NSGlobalDomain"
          ".GlobalPreferences"
          "LaunchServices"
          "menuExtraClock"
          "dock"
          "finder"
          "hitoolbox"
          "iCal"
          "magicmouse"
          "screencapture"
          "screensaver"
          "spaces"
          "trackpad"
          "universalaccess"
          "ActivityMonitor"
          "WindowManager"
          "controlcenter"
          "CustomUserPreferences"
          "loginwindow"
          "smb"
          "SoftwareUpdate"
          "CustomSystemPreferences"
        ]
      ) (builtins.attrNames cfg);
      message = "Incremental defaults must cover every nix-darwin preference domain.";
    }
  ];
  system.activationScripts.userDefaults.text = lib.mkForce ''
    /bin/launchctl asuser "$(id -u -- ${lib.escapeShellArg config.system.primaryUser})" \
      /usr/bin/sudo --user=${lib.escapeShellArg config.system.primaryUser} --set-home \
      ${runner} ${render "user-defaults.json" users}
  '';
  system.activationScripts.defaults.text = lib.mkForce ''
    ${runner} ${render "system-defaults.json" systems}
  '';
}
