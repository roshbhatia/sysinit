# The pi settings keys this repository declares, and the ones it does not.
# Read by `config/pi.nix` and by the `pi-settings-keys-exist` flake check; a
# second copy in the check is what let `showLastPrompt` go unverified.
{
  # repository policy, or derived from something Nix owns
  declared = [
    "packages"
    "quietStartup"
    "theme"
    "enableInstallTelemetry"
    "shellCommandPrefix"
    "skills"
    "externalEditor"
  ];

  # owner preference: a declared key wins on every activation and would revert
  # the runtime choice
  ownerPreference = [
    "defaultProvider"
    "defaultModel"
    "defaultThinkingLevel"
    "hideThinkingBlock"
  ];

}
