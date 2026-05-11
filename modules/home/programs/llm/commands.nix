{
  pkgs,
  ...
}:

let
  opsxCommands = {
    propose = import ./commands/opsx/propose.nix;
    apply = import ./commands/opsx/apply.nix;
    explore = import ./commands/opsx/explore.nix;
    archive = import ./commands/opsx/archive.nix;
  };

  renderedOpsx = builtins.mapAttrs (
    name: content: pkgs.writeText "opsx-${name}.md" content
  ) opsxCommands;

  installCommandsTo = _basePath: builtins.mapAttrs (_name: path: { source = path; }) renderedOpsx;
in
{
  inherit opsxCommands renderedOpsx installCommandsTo;
}
