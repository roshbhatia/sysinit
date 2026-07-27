# Harness vocabulary. One concept, one word per harness.
#
# A spawned helper agent is the same thing everywhere, but the harnesses do not
# agree on its name: Claude Code's own tools and UI say "teammate", every other
# harness says "subagent". Naming it with the wrong word forces the model to
# translate before it can act, which is the fragmented-wording failure that
# instructions.nix principle 4 exists to prevent.
#
# So source text is authored once with a placeholder, and each harness's
# renderer substitutes that harness's own word:
#
#   "Spawn one {{agent}} per lens."
#     -> claude:  "Spawn one teammate per lens."
#     -> default: "Spawn one subagent per lens."
#
# Applied by instructions.nix, skills.nix, and subagents/default.nix — the three
# renderers that already take a `harness` argument.
{ lib }:
let
  terms = {
    claude = {
      agent = "teammate";
      agents = "teammates";
    };
    default = {
      agent = "subagent";
      agents = "subagents";
    };
  };

  termsFor = harness: if terms ? ${harness} then terms.${harness} else terms.default;

  # Sentence-initial forms are derived, not stored, so a term cannot drift
  # between its lowercase and capitalized spellings.
  applyVocab =
    harness: text:
    let
      t = termsFor harness;
    in
    builtins.replaceStrings
      [
        "{{agent}}"
        "{{agents}}"
        "{{Agent}}"
        "{{Agents}}"
      ]
      [
        t.agent
        t.agents
        (lib.toSentenceCase t.agent)
        (lib.toSentenceCase t.agents)
      ]
      text;
in
{
  inherit terms termsFor applyVocab;
}
