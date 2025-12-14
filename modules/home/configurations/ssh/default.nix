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
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        addKeysToAgent = "yes";
        hashKnownHosts = true;
      };
    };
  };

  # Only set authorized_keys on Linux (NixOS)
  # Note: This is also set at system level in modules/nixos/configurations/ssh.nix
  home.file = lib.optionalAttrs isLinux {
    ".ssh/authorized_keys" = {
      text = ''
        # GitHub (Default) SSH Key - from 1Password
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbqXvBhZI87E+Jj1i9L1MqQ71JRPofArCC0iRvZRIMV
      '';
    };
  };
}
