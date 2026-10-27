{ inputs }:
final: _prev:
let
  inherit (final) lib;
  inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
  pythonSetFor =
    workspaceRoot:
    let
      workspace = uv2nix.lib.workspace.loadWorkspace { inherit workspaceRoot; };
    in
    (final.callPackage pyproject-nix.build.packages { python = final.python313; }).overrideScope (
      lib.composeManyExtensions [
        pyproject-build-systems.overlays.wheel
        (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
      ]
    );
  pythonToolsSet = pythonSetFor ../pkgs/python-tools;
  conductorPythonSet = (pythonSetFor ../pkgs/conductor).overrideScope (
    _pythonFinal: pythonPrev: {
      claude-agent-sdk = pythonPrev.claude-agent-sdk.overrideAttrs (old: {
        # Reuse the managed Claude CLI through the SDK's PATH fallback.
        postInstall = (old.postInstall or "") + ''
          rm -f "$out/${final.python313.sitePackages}/claude_agent_sdk/_bundled/claude"
        '';
      });
    }
  );
  inherit (final.callPackages pyproject-nix.build.util { }) mkApplication;
  application =
    pythonSet: name: extras:
    mkApplication {
      venv = pythonSet.mkVirtualEnv "${name}-env" { ${name} = extras; };
      package = pythonSet.${name};
    };
in
{
  ast-grep-mcp = application pythonToolsSet "sg-mcp" [ ];
  acp-amp = application pythonToolsSet "acp-amp" [ ];
  conductor-cli =
    (application conductorPythonSet "conductor-cli" [
      "claude-agent-sdk"
      "telemetry"
      "tui"
    ]).overrideAttrs
      (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [ final.makeWrapper ];
        postInstall = ''
          conductorEntrypoint="$(readlink "$out/bin/conductor")"
          rm "$out/bin/conductor"
          makeWrapper "$conductorEntrypoint" "$out/bin/conductor" \
            --set CONDUCTOR_NO_UPDATE_CHECK 1 \
            --set-default COPILOT_CLI_PATH ${lib.getExe final.github-copilot-cli} \
            --prefix PATH : ${
              lib.makeBinPath [
                final.github-copilot-cli
                final.claude-code
              ]
            }
        '';
        doInstallCheck = true;
        installCheckPhase = ''
          "$out/bin/conductor" --version
          "$out/bin/conductor" --help > /dev/null
          "$out/bin/conductor" validate ${../pkgs/conductor/check.yaml}
          "$out/bin/conductor" --silent run ${../pkgs/conductor/check.yaml} > result.json
          ${lib.getExe final.python313} -c 'import json; assert json.load(open("result.json")) == {"message": "conductor-ready"}'
        '';
        meta = old.meta // {
          description = "Microsoft Conductor workflow CLI and local dashboard";
          homepage = "https://github.com/microsoft/conductor";
          mainProgram = "conductor";
        };
      });
}
