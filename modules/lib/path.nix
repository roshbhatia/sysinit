{ lib, ... }:

{
  mkPathExporter = {
    name,
    additionalPaths ? [],
  }: let
    defaultPaths = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/usr/bin"
      "/usr/local/opt/cython/bin"
      "/usr/sbin"
      "$HOME/.krew/bin"
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "$HOME/.npm-global/bin/yarn"
      "$HOME/.rvm/bin"
      "$HOME/.yarn/bin"
      "$HOME/bin"
      "$HOME/go/bin"
      "$XDG_CONFIG_HOME/.cargo/bin"
      "$XDG_CONFIG_HOME/yarn/global/node_modules/.bin"
      "$XDG_CONFIG_HOME/zsh/bin"
      "$HOME/.uv/bin"
      "$HOME/.yarn/global/node_modules/.bin"
      "$HOME/.cargo/bin"
      "/bin"
      "/sbin"
    ];
    allPaths = lib.unique (defaultPaths ++ additionalPaths);
    escapedPaths = lib.concatStringsSep ":" allPaths;
  in {
    after = [ "fixVariables" ];
    before = [];
    data = ''
      export PATH="${escapedPaths}:$PATH"
      log_debug "Exported PATH: $PATH"
    '';
  };
}
