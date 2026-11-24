{
  pkgs,
  darwinConfigurations,
  nixosConfigurations,
}:

let
  arrakis = nixosConfigurations.arrakis.config;
  arrakisUser = "rshnbhatia";
  arrakisKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPaCcHii525hx5Roh8kYyisdIjXVG3t4tkKwhcwUwXS rshnbhatia@arrakis";
  arrakisSsh = arrakis.home-manager.users.${arrakisUser}.programs.ssh.settings."*".data;
  lv426 = darwinConfigurations.lv426.config;
in
assert arrakisSsh.IdentityFile == "~/.ssh/id_ed25519_personal";
assert arrakisSsh.IdentitiesOnly;
assert !(arrakisSsh ? IdentityAgent);
assert builtins.elem "fmask=0077" arrakis.fileSystems."/boot".options;
assert builtins.elem "dmask=0077" arrakis.fileSystems."/boot".options;
assert builtins.elem arrakisKey lv426.users.users.${arrakisUser}.openssh.authorizedKeys.keys;
pkgs.runCommand "host-access-security" { } ''
  touch "$out"
''
