{
  lib,
  osConfig ? { },
  ...
}:

let
  hasNixOSSystem = osConfig ? system && osConfig.system ? stateVersion;
  isLinux = hasNixOSSystem;
in
{
  programs.ssh = {
    enable = true;
    # Disable future-deprecated default config; we set our own matchBlocks."*"
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        hashKnownHosts = true;
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  home.file = lib.optionalAttrs isLinux {
    ".ssh/authorized_keys" = {
      text = ''
        # GitHub (Default) SSH Key - from 1Password
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbqXvBhZI87E+Jj1i9L1MqQ71JRPofArCC0iRvZRIMV
      '';
    };
  };
}
