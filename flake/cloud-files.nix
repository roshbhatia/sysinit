{ pkgs, lib }:
let
  facts = import ../modules/shared/cloud.nix { inherit lib; };

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
