# The pi settings keys this repository declares, and the ones it does not.
# Read by `config/pi.nix` and by the `pi-settings-keys-exist` flake check; a
# second copy in the check is what let `showLastPrompt` go unverified.
{
  # repository policy, or derived from something Nix owns
  declared = [
    "packages"
    "theme"
    "enableInstallTelemetry"
    "shellCommandPrefix"
    "skills"
    "externalEditor"
  ];

  # owner preference: a declared key wins on every activation and would revert
  # the runtime choice
  ownerPreference = [
    # Display-only, so declaring it would revert an owner who turns the startup
    # header back on from `/settings`. Its peer `hideThinkingBlock` is here for the
    # same reason. Every declared key is enforced now, which is what made this a real
    # regression rather than a style question.
    "quietStartup"
    "defaultProvider"
    "defaultModel"
    "defaultThinkingLevel"
    "hideThinkingBlock"
  ];

  # absent from the installed build, so deleted before the merge as a deep merge
  # cannot remove a key on its own
  retired = [
    "showLastPrompt"
    "powerline"
  ];
}
