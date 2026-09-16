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
pkgs.runCommand "editor-composition-test"
  {
    nativeBuildInputs = with pkgs; [
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
  ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/helix"
    cp ${
      home.config.xdg.configFile."helix/languages.toml".source
    } "$XDG_CONFIG_HOME/helix/languages.toml"
    cp ${home.config.xdg.configFile."helix/config.toml".source} "$XDG_CONFIG_HOME/helix/config.toml"
    for language in nix python go dockerfile markdown hcl tfvars; do
      hx --health "$language" > "$TMPDIR/$language-health"
      cat "$TMPDIR/$language-health"
      if grep -q 'not found in' "$TMPDIR/$language-health"; then
        exit 1
      fi
    done
    touch "$out"
  ''
