# Harness vocabulary. One concept, one word per harness.
#
# A spawned helper agent is the same thing everywhere, but the harnesses do not
# agree on its name: Claude Code's own tools and UI say "teammate", every other
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

  termsFor = harness: terms.${harness} or terms.default;

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
