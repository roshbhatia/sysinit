{
  values,
  config,
  ...
}:
{
  # Immutable users - all user configuration comes from NixOS config
  users.mutableUsers = false;

  users.groups = {
    "${values.user.username}" = { };
    podman = { };
    wireshark = { };
    # for android platform tools's udev rules
    adbusers = { };
    dialout = { };
    # for openocd (embedded system development)
    plugdev = { };
    # misc
    uinput = { };
  };

  users.users."${values.user.username}" = {
    home = "/home/${values.user.username}";
    isNormalUser = true;
    createHome = true;
    group = values.user.username;
    extraGroups = [
      "users"
      "wheel"
      "networkmanager"
      "podman"
      "wireshark"
      "adbusers"
      "dialout"
      "plugdev"
      "uinput"
    ]
    ++ (if config.programs.gamemode.enable then [ "gamemode" ] else [ ]);
    description = values.git.name;
  };

  # Allow wheel group to use sudo without password
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
