final: _prev: {
  ask = final.buildGoModule {
    pname = "ask";
    version = "0.1.0";

    src = ../pkgs/ask;

    # A hash, not null: ask draws its progress view with bubbletea, lipgloss, and bubbles.
    # Recompute it with `nix build` and copy the reported value on a dependency bump.
    vendorHash = "sha256-266e4R7R5pNSdHPFubpfDIgf8JZ7o9cel4/UXuy8j/8=";

    meta = {
      description = "Pipe something into a coding agent and print the answer, and only the answer";
      mainProgram = "ask";
      platforms = final.lib.platforms.unix;
    };
  };
}
