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
          rev = "main";
          sha256 = "0000000000000000000000000000000000000000000000000000";
        }
        + "/lib/vm-shell.nix"
      )
      {
        inherit pkgs;
        inherit (pkgs) lib;
      };

  projectName = builtins.baseNameOf (builtins.toString ./.);
  vmName = "${projectName}-minimal";

in
pkgs.mkShell {
  name = "${projectName}-minimal-shell";

  buildInputs = with pkgs; [ ];

  shellHook = ''
    # Prevent nested VM entry
    if [[ -n "''${SYSINIT_IN_VM:-}" ]]; then
      echo "Already in VM. Skipping auto-entry."
      return 0
    fi

    # Disable auto-entry if requested
    if [[ -n "''${SYSINIT_NO_AUTO_VM:-}" ]]; then
      echo "Auto VM entry disabled. Run 'task lima:shell' to connect manually."
      return 0
    fi

    # Ensure VM exists and is running
    ${vmLib.ensureVM {
      inherit vmName projectName;
      projectDir = "$(pwd)";
      image = "lima-minimal";
      cpus = 2;
      memory = "4GiB";
      ports = [
        3000
        8080
      ];
      verbose = true;
    }}

    # Auto-enter VM
    ${vmLib.enterVM vmName projectName true}
  '';
}
