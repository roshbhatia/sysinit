{ pkgs, ... }:
let
  personal = import ../personal.nix;
in
{
  environment.packages = with pkgs; [
    curl
    git
    jq
    openssh
  ];

  nix.extraOptions = "experimental-features = nix-command flakes";
  system.stateVersion = "24.05";
  home-manager.config = {
    home.stateVersion = "24.05";
    programs = {
      git = {
        enable = true;
        settings.user = { inherit (personal.git) name email; };
      };
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings.vorgossos = {
          HostName = "vorgossos.stork-eel.ts.net";
          User = "rshnbhatia";
        };
      };
      neovim = {
        enable = true;
        defaultEditor = true;
        withPython3 = false;
        withRuby = false;
        initLua = ''
          vim.opt.number = true
          vim.opt.signcolumn = "no"
          vim.opt.wrap = true
        '';
      };
    };
  };
}
