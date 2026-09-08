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

  # The blueprint is a structured document Devin reads and a human edits, so it
  # is written as text rather than through `pkgs.formats.yaml`, which emits a
  # `%YAML 1.1` header, sorts keys, and quotes the multi-line knowledge block.
  # The build proves the text parses to the same structure the facts hold.
  blueprint = {
    initialize = [
      {
        name = facts.devin.stepName;
        run = "bash ${facts.setupScript}";
      }
    ];
    knowledge = [ facts.devin.knowledge ];
  };
  indent =
    prefix: text:
    lib.concatMapStringsSep "\n" (line: prefix + line) (
      lib.splitString "\n" (lib.removeSuffix "\n" text)
    );
  blueprintYaml =
    pkgs.runCommand "blueprint.yaml"
      {
        nativeBuildInputs = [
          pkgs.yq-go
          pkgs.jq
          pkgs.yamllint
        ];
        expected = builtins.toJSON blueprint;
        passAsFile = [ "expected" ];
      }
      ''
        cp ${pkgs.writeText "blueprint.yaml" ''
          # Generated from modules/shared/cloud.nix by flake/cloud-files.nix.
          # Do not edit by hand; run hack/generate-cloud.sh.
          initialize:
            - name: ${facts.devin.stepName}
              run: bash ${facts.setupScript}

          knowledge:
            - name: ${facts.devin.knowledge.name}
              contents: |
          ${indent "      " facts.devin.knowledge.contents}
        ''} $out
        yamllint -c ${../.yamllint.yml} $out
        diff <(yq -o=json $out | jq -S .) <(jq -S . "$expectedPath")
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
    blueprintYaml
    setupScript
    ;

  # Mirrors the repo paths, so the generator and the check copy by name.
  all = pkgs.linkFarm "sysinit-cloud-files" [
    {
      name = ".cursor/environment.json";
      path = environmentJson;
    }
    {
      name = ".devin/blueprint.yaml";
      path = blueprintYaml;
    }
    {
      name = facts.setupScript;
      path = setupScript;
    }
  ];
}
