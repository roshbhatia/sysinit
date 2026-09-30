{ inputs }:
final: _prev:
let
  inherit (final) lib;
  inherit (inputs.hermes-agent.inputs) uv2nix pyproject-nix pyproject-build-systems;
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ../pkgs/python-tools; };
  pythonSet =
    (final.callPackage pyproject-nix.build.packages { python = final.python313; }).overrideScope
      (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
        ]
      );
  inherit (final.callPackages pyproject-nix.build.util { }) mkApplication;
  application =
    name:
    mkApplication {
      venv = pythonSet.mkVirtualEnv "${name}-env" { ${name} = [ ]; };
      package = pythonSet.${name};
    };
in
{
  basic-memory = application "basic-memory";
  ast-grep-mcp = application "sg-mcp";
  acp-amp = application "acp-amp";
}
