{ pkgs, homeManagerLib }:
let
  home = homeManagerLib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs.profile = "dev";
    modules = [
      ../modules/home/programs/helix.nix
      {
        home = {
          username = "editor-test";
          homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin then "/Users/editor-test" else "/home/editor-test";
          stateVersion = "25.11";
        };
      }
    ];
  };
in
assert !(home.config.programs.helix.settings.editor ? clipboard-provider);
import ./lib.nix { inherit pkgs; } {
  name = "editor-composition-test";
  script = "editor-composition.nu";
  arguments = [
    home.config.xdg.configFile."helix/languages.toml".source
    home.config.xdg.configFile."helix/config.toml".source
  ];
  inputs = with pkgs; [
    helix
    nixd
    nixfmt
    pyright
    ruff
    gopls
    delve
    docker-language-server
    markdown-oxide
    tofu-ls
  ];
}
