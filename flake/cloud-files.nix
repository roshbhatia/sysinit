# Renders the cloud-agent files from `modules/shared/cloud.nix`. The outputs are
# committed at the repo root because Cursor and Devin read them from the
# checkout, and home-manager cannot write into one. `hack/generate-cloud.sh`
# copies them in; `checks/cloud-files.nix` fails when the copy drifts.
{ pkgs, lib }:
let
  facts = import ../modules/shared/cloud.nix { inherit lib; };

  # Key order follows the Nix attrset (sorted); jq re-indents to two spaces.
  environmentJson = pkgs.runCommand "environment.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq . ${
      pkgs.writeText "environment.json" (
        builtins.toJSON {
          inherit (facts.cursor) name egressMode;
          install = "bash ${facts.setupScript}";
          inherit (facts) egressAllowlist;
        }
      )
    } > $out
  '';

  setupScript =
    pkgs.runCommand "cloud-setup.sh"
      {
        nativeBuildInputs = [
          pkgs.shellcheck
          pkgs.shfmt
        ];
      }
      ''
        cp ${
          pkgs.replaceVars ./cloud/cloud-setup.sh.in {
            cachixUrl = facts.cachix.url;
            cachixKey = facts.cachix.publicKey;
            nixosCacheUrl = facts.nixosCache.url;
            installerUrl = facts.installer.url;
            installerFlags = lib.escapeShellArgs facts.installer.flags;
            inherit (facts) flakeRef binDir;
          }
        } $out
        shellcheck --shell=bash $out
        shfmt -i 2 -ci -sr -s -d $out
      '';
in
{
  inherit
    facts
    environmentJson
    setupScript
    ;

  # Mirrors the repo paths, so the generator and the check copy by name.
  all = pkgs.linkFarm "sysinit-cloud-files" [
    {
      name = ".cursor/environment.json";
      path = environmentJson;
    }
    {
      name = facts.setupScript;
      path = setupScript;
    }
  ];
}
