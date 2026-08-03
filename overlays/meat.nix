{
  inputs,
  ...
}:

final: _prev: {
  # Abridges a unified diff into a "reading diff": an LLM plans line removals and
  # folds, and meat's own compiler applies that plan to the immutable input, so
  # the model never authors the displayed diff.
  #
  # Deliberately NOT wired into the spec-driven apply loop. It calls an LLM, so
  # its output is not reproducible, it costs 45-110s and up to 235k input tokens
  # per run on the owner's own key, and it never sees a change's `Behavior`
  # criteria, so it cannot say whether a diff does what the change promised. It
  # earns its place as a manual tool for a diff too large to read, nothing more.
  #
  # Unfree because upstream ships no LICENSE at all (boldsoftware/meat#2), which
  # means default copyright rather than a permissive grant. Building from source
  # for personal use is fine; redistributing the result is not, so this must stay
  # out of any public binary cache. Revisit the license once #2 is answered.
  meat = final.buildGoModule {
    pname = "meat";
    # No tags and no releases upstream, so the pin is the commit date.
    version = "0-unstable-2026-08-02";

    src = inputs.meat;

    # Upstream's go.mod has no `require` block: meat is standard library only, by
    # design, so there is nothing to vendor.
    vendorHash = null;

    subPackages = [ "cmd/meat" ];

    # The test suite reaches for `git` and, in places, the network. Building the
    # binary is the only thing this derivation is for.
    doCheck = false;

    meta = with final.lib; {
      description = "Abridge a code diff into a reading diff";
      homepage = "https://github.com/boldsoftware/meat";
      license = licenses.unfree;
      mainProgram = "meat";
      platforms = platforms.unix;
    };
  };
}
