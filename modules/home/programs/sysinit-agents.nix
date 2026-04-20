{ lib, pkgs, config, ... }:
let
  agentsRepo = "https://github.com/roshbhatia/sysinit.agents.git";
  agentsDir = "${config.xdg.configHome}/sysinit.agents";
in
{
  # Ensure runtime deps for the install script are available.
  home.packages = with pkgs; [
    git
    nodejs_22
    jq
  ];

  # Clone/update sysinit.agents then run install.sh on every switch.
  home.activation.sysinit-agents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.git}/bin:${pkgs.nodejs_22}/bin:${pkgs.jq}/bin:$PATH"
    AGENTS_DIR="${agentsDir}"
    if [ ! -d "$AGENTS_DIR/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone "${agentsRepo}" "$AGENTS_DIR"
    else
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$AGENTS_DIR" pull --ff-only --quiet
    fi
    $DRY_RUN_CMD bash "$AGENTS_DIR/install.sh" --quiet --skip-tools
  '';
}
