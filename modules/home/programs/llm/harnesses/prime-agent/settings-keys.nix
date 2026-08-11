{
  # Written on every activation and reasserted by `enforce`. Each name is one of
  # the 43 keys on `interface Settings` in
  # `dist/core/settings-manager.d.ts` of prime-agent 0.7.1.
  declared = [
    "packages"
    "skills"
    "quietStartup"
    "shellCommandPrefix"
  ];

  # Runtime choices the owner makes inside prime-agent. Declaring one of these
  # would revert their pick on every switch, so the assertion in `default.nix`
  # keeps the two lists disjoint.
  ownerPreference = [
    "defaultProvider"
    "defaultModel"
    "defaultThinkingLevel"
    "theme"
    "hideThinkingBlock"
    "onboardingCompleted"
  ];

  # Deleted from the file on every activation.
  #
  # `externalEditor`, `enableInstallTelemetry`, and `enableAnalytics` are NOT
  # retired here even though pi and atomic declare them: prime-agent's Settings
  # interface has no such key, so it never wrote one and there is nothing to
  # delete. Retiring a key the harness cannot produce is noise.
  retired = [ ];
}
