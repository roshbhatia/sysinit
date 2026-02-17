{
  pkgs ? import <nixpkgs> { },
}:

let
  # Fetch VM library from sysinit repo
  vmLib =
    import
      (
        pkgs.fetchFromGitHub {
          owner = "roshbhatia";
          repo = "sysinit";
          rev = "ba1035ac4b4edc19634fe60c53bc0f136141db0b";
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        }
        + "/lib/vm-shell.nix"
      )
      {
        inherit pkgs;
        inherit (pkgs) lib;
      };

  inherit (pkgs) lib;

  projectName = builtins.baseNameOf (builtins.toString ./.);
  vmName = "${projectName}-dev";

  # Import existing shell.nix if it exists
  baseShell =
    if builtins.pathExists ./shell.nix then import ./shell.nix { inherit pkgs; } else pkgs.mkShell { };

in
pkgs.mkShell {
  name = "${projectName}-vm-shell";

  # Merge buildInputs from existing shell.nix if present
  buildInputs =
    (baseShell.buildInputs or [ ])
    ++ (with pkgs; [
      # VM management dependencies
      lima
      jq
    ]);

  shellHook = ''
    # Prevent nested VM entry
    if [[ -n "''${SYSINIT_IN_VM:-}" ]]; then
      echo "Already in VM. Skipping auto-entry."
      return 0
    fi

    # Disable auto-entry if requested
    if [[ -n "''${SYSINIT_NO_AUTO_VM:-}" ]]; then
      echo "Auto VM entry disabled. Run 'limactl shell ${vmName}' to connect manually."
      return 0
    fi

    # Ensure VM exists and is running
    ${vmLib.ensureVM {
      inherit vmName projectName;
      projectDir = "$(pwd)";
      image = "lima-dev";
      cpus = 4;
      memory = "8GiB";
      ports = [
        3000
        8080
        5173
        5432
      ];
      verbose = true;
    }}

    # Auto-enter VM
    ${vmLib.enterVM vmName projectName true}
  '';
}
