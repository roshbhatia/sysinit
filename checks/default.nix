{
  pkgs,
  ...
}:
{
  editor-config = import ./editor-config.nix { inherit pkgs; };
  go-tests = pkgs.sysinit-gotools;
  orca-no-startup-units = pkgs.runCommand "orca-no-startup-units" { } ''
    test ! -e ${pkgs.orca}/etc/systemd
    test ! -e ${pkgs.orca}/lib/systemd
    test ! -e ${pkgs.orca}/Library/LaunchAgents
    test ! -e ${pkgs.orca}/Library/LaunchDaemons
    touch $out
  '';
  colchis-workflow-schema =
    pkgs.runCommand "colchis-workflow-schema" { nativeBuildInputs = [ pkgs.cue ]; }
      ''
        cue vet ${../pkgs/colchis/schemas/workflow/v1/schema.cue} \
          ${../pkgs/colchis/schemas/workflow/v1/testdata/valid.json} -d '#Workflow'
        cue vet ${../pkgs/colchis/schemas/workflow/v1/schema.cue} \
          ${../pkgs/colchis/examples/openspec-pi.json} -d '#Workflow'
        if cue vet ${../pkgs/colchis/schemas/workflow/v1/schema.cue} \
          ${../pkgs/colchis/schemas/workflow/v1/testdata/invalid-unbounded-loop.json} -d '#Workflow'; then
          echo "unbounded loop fixture passed validation" >&2
          exit 1
        fi
        if cue vet ${../pkgs/colchis/schemas/workflow/v1/schema.cue} \
          ${../pkgs/colchis/schemas/workflow/v1/testdata/invalid-effect-authority.json} -d '#Workflow'; then
          echo "unauthorized effect fixture passed validation" >&2
          exit 1
        fi
        touch $out
      '';
}
