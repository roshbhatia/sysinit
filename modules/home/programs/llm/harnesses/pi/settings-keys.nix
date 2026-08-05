# The pi settings keys this repository declares, and the ones it does not.
# Read by `harnesses/pi/default.nix` and by the `pi-settings-keys-exist` flake check; a
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
    # Moved out of `ownerPreference` deliberately. That entry argued declaring it
    # would revert an owner who re-enables the header from `/settings`. The owner has
    # since asked for the header off as policy, so enforcing it is the intent rather
    # than a regression. `--verbose` still forces it back for a single run, which is
    # the escape hatch the runtime setting was protecting.
    "quietStartup"
  ];

  # owner preference: a declared key wins on every activation and would revert
  # the runtime choice
  ownerPreference = [
    # `hideThinkingBlock` stays here: display-only, and declaring it would revert an
    # owner who toggles it from `/settings`. `quietStartup` was here for the same
    # reason and is now declared, because the owner asked for the header off.
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
