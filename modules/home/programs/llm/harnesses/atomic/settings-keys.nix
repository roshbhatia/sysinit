{
  # Written on every activation and reasserted by `enforce`.
  declared = [
    "packages"
    "skills"
    "quietStartup"
    "externalEditor"
    "enableInstallTelemetry"
    "enableAnalytics"
    "shellCommandPrefix"
  ];

  # Runtime choices the owner makes inside atomic. Declaring one of these would
  # revert their pick on every switch, so the assertion in `default.nix` keeps
  # the two lists disjoint.
  ownerPreference = [
    "defaultProvider"
    "defaultModel"
    "defaultThinkingLevel"
    "theme"
    "lastChangelogVersion"

    # atomic's onboarding marker, the counterpart of prime-agent's
    # `onboardingCompleted`.
    "onboardedVersion"
  ];

  # Deleted from the file on every activation.
  retired = [ ];
}
