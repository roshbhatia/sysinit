{
  hostName,
  lib,
  pkgs,
  ...
}:
let
  personal = import ../personal.nix;
in
{
  imports = [ ../../features/theme/nix-on-droid.nix ];

  environment.etc."hostname".text = "${hostName}\n";

  environment.packages = with pkgs; [
    curl
    git
    jq
    openssh
  ];

  nix.extraOptions = "experimental-features = nix-command flakes";
  system.stateVersion = "24.05";
  user.shell = lib.getExe pkgs.nushell;

  home-manager.config = {
    imports = [
      ../../features/git/identity.nix
      ../../features/nushell/interactive.nix
      ../../features/ssh/client.nix
    ];

    home.stateVersion = "24.05";
    sysinit.git = { inherit (personal.git) name email; };
    programs.ssh.settings.vorgossos = {
      HostName = "vorgossos.stork-eel.ts.net";
      User = "rshnbhatia";
    };
  };
}
