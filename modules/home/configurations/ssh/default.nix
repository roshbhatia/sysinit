{
  lib,
  osConfig ? { },
  ...
}:

let
  isLinux = osConfig.system or null != null;
in
{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    hashKnownHosts = true;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };

  # Only set authorized_keys on Linux (NixOS)
  home.file = lib.optionalAttrs isLinux {
    ".ssh/authorized_keys" = {
      text = ''
        # SSH public keys go here
        # Can be managed via 1Password or directly added
      '';
    };
  };
}
