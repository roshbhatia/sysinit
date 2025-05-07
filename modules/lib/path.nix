{ lib, ... }:

{
  mkPathExporter = {
    name,
    additionalPaths ? [],
  }: let
    defaultPaths = [
      "/usr/bin"
      "/usr/sbin"
      "/bin"
      "/sbin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
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
