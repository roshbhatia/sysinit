{
  config,
  pkgs,
  values,
  ...
}:
{
  # Define user account
  users.users.${values.user.username} = {
    isNormalUser = true;
    description = values.user.username;
    extraGroups = [
      "wheel" # Enable sudo
      "networkmanager" # Network management
      "docker" # Docker access
      "video" # Video devices
      "audio" # Audio devices
    ];
    shell = pkgs.zsh;
  };

  # Enable ZSH system-wide
  programs.zsh.enable = true;

  # Enable sudo for wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
