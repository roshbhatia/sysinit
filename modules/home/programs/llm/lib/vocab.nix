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
