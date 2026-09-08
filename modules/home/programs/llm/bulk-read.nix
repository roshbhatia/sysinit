# The bulk-read seam between gate and ask, in one place.
#
# `read-router` and `bash-guard` deny a whole-file read and print `reader` as
# the alternative. `skill-tools.nix` renders the template that command resolves
# to. Both import this file, so the invocation and the template cannot drift.
rec {
  name = "bulk-read";
  schema = "${name}-result";
  # The provider is pinned here rather than passed on the command line, and the
  # model is the role word, so each provider names its own cheap model.
  provider = "claude";
  model = "light";
  reader = "ask -t ${name}";
}
