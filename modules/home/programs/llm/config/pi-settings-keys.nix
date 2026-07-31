# The pi settings keys this repository declares, and the ones it deliberately
# does not, in one place.
#
# Two consumers read this: `config/pi.nix`, which asserts its rendered settings
# match `declared` exactly, and the `pi-settings-keys-exist` flake check, which
# asserts every declared key exists in the installed pi binary and every retired
# key does not.
#
# A second hand-written copy of this list in the check was the drift risk that
# motivated the file: adding a key to pi.nix without touching the check would
# have left the new key unverified against the binary, which is how
# `showLastPrompt` survived for months.
{
  # Declared because the value is repository policy, or is derived from
  # something Nix owns. Nix wins for these on every activation.
  declared = [
    "packages" # extension load order, defined by this module
    "quietStartup" # display policy for this machine
    "theme" # generated from stylix; selecting it is the point
    "enableInstallTelemetry" # Nix owns updates, so the ping is off
    "shellCommandPrefix" # derived from the zsh config this repo owns
    "skills" # points at the Nix-managed skills tree
    "externalEditor" # points at a Nix-built binary
  ];

  # Declared once, now handed back. Nix must NOT set these: a declared key wins
  # on every activation and would revert the owner's runtime choice.
  ownerPreference = [
    "defaultProvider"
    "defaultModel"
    "defaultThinkingLevel"
    "hideThinkingBlock"
  ];

  # Absent from the installed pi build. Deleted from the live settings file on
  # every activation, because a deep merge cannot remove a key on its own.
  retired = [
    "showLastPrompt"
    "powerline"
  ];
}
