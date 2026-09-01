{ lib }:
let
  subagents = import ../subagents { inherit lib; };
  vocab = import ./vocab.nix { inherit lib; };

  renderRule = item: ''
    - ${item.rule} ${item.reason}

    <example>
    <bad>${item.bad}</bad>
    <good>${item.good}</good>
    </example>
  '';

  renderRules = rules: builtins.concatStringsSep "\n" (map renderRule rules);

  formatSkillsBlock =
    skills:
    let
      names = builtins.attrNames skills;
    in
    if names == [ ] then
      "(no skills registered)"
    else
      "Available: " + builtins.concatStringsSep ", " (map (name: "`${name}`") names);

  registry = import ../harnesses/registry.nix;
  harnessesWithoutSkillLoader = builtins.attrNames (
    lib.filterAttrs (_name: harness: !harness.skillLoader) registry
  );

  contextRules = renderRules [
    {
      rule = "Read the repository context before you edit: `AGENTS.md`, active changes, and local lessons.";
      reason = "Repository facts have priority over general habits.";
      bad = "Assume the build command from another repository.";
      good = "Read `AGENTS.md`, then use the command it defines.";
    }
    {
      rule = "Load a skill when its domain matches the task.";
      reason = "Skills provide detailed rules only when the task needs them.";
      bad = "Carry every commit, review, and documentation rule in global context.";
      good = "Load `writing-commit-message` before you create a commit.";
    }
    {
      rule = "Keep the user in control of decisions, artifacts, and external changes.";
      reason = "Model output is a draft until evidence or the user accepts it.";
      bad = "State that the user approved an option they did not choose.";
      good = "State the verified result and leave the decision with the user.";
    }
    {
      rule = "Use the repository's Nix shell for dependencies, and edit the Nix source for managed configuration.";
      reason = "Global installs and generated files bypass the declared system.";
      bad = "Install a missing linter globally or edit its store symlink.";
      good = "Add the linter to the Nix shell and edit its source module.";
    }
    {
      rule = "Preserve Git history and hooks.";
      reason = "Bypass flags and destructive commands remove review and recovery paths.";
      bad = "Use `--no-verify`, force-push, or `reset --hard` to finish faster.";
      good = "Fix the hook failure and use a recoverable Git operation.";
    }
    {
      rule = "Stop on an unexpected error, keep its evidence, and fix its cause.";
      reason = "Continuing from an unexplained failure makes later evidence unreliable.";
      bad = "Retry with a bypass flag after an unknown build failure.";
      good = "Read the failing log, fix the cause, then rerun the same check.";
    }
    {
      rule = "Inspect the complete diff and run checks that prove the changed behavior.";
      reason = "A successful edit or build does not prove the user flow.";
      bad = "Report success after the compiler exits zero.";
      good = "Inspect the diff, run the suite, and test the changed command.";
    }
    {
      rule = "Do not add type suppressions, emojis, or vendored upstream updates without explicit permission.";
      reason = "These changes hide type failures or alter owner-managed content.";
      bad = "Add `any` to silence a type error or refresh a vendor tree incidentally.";
      good = "Fix the type and leave upstream vendor drift for its sync command.";
    }
  ];

  makeInstructions =
    {
      harness,
      localSkillDescriptions,
      skillsRoot ? "~/.claude/skills",
      extraSections ? [ ],
    }:
    let
      skillsList = formatSkillsBlock localSkillDescriptions;
      loaderNote = lib.optionalString (builtins.elem harness harnessesWithoutSkillLoader) ''

        Skills live at `${skillsRoot}/<name>/SKILL.md`. Read a matching skill directly.

        ${skillsList}
      '';
      extraText = section: ''

        ${section.body}
      '';
      extras = builtins.concatStringsSep "\n" (map extraText extraSections);
      base = ''
        ${contextRules}
        ${loaderNote}
      '';
    in
    vocab.applyVocab harness (base + lib.optionalString (extraSections != [ ]) "\n${extras}");

  outputStyleRules = ''
    Use Simplified Technical English for chat, reviews, and documents.

    ${renderRules [
      {
        rule = "Use active voice, one term per concept, sentences under 25 words, and paragraphs under 7 sentences.";
        reason = "Short literal text reduces rereading.";
        bad = "It should be noted that the configuration may potentially be changed by the command.";
        good = "The command can change the configuration.";
      }
      {
        rule = "Lead with the answer or action, then include only evidence that changes the next step.";
        reason = "The reader must find the result without reading narration.";
        bad = "I will inspect the files, run tests, and then share what I find.";
        good = "The test fails because `config.nix:12` shadows `utils`.";
      }
      {
        rule = "Use the smallest structure that makes the answer clear.";
        reason = "Extra headings, repeated summaries, filler, and marketing words add noise.";
        bad = "## Result\n\n- Status: successful\n- Outcome: all three tests passed";
        good = "All 3 tests passed.";
      }
      {
        rule = "Keep complete errors, security findings, destructive-action confirmations, and requested explanations.";
        reason = "Correctness and user control have priority over brevity.";
        bad = "The command failed. I omitted the error for brevity.";
        good = "The command failed with exit 2: `unknown option: --force`.";
      }
      {
        rule = "Load the matching writing skill for commits, code comments, documents, PRs, or prose in the user's name.";
        reason = "Those formats need rules that do not belong in every request.";
        bad = "Apply every PR-writing rule to a one-line status answer.";
        good = "Load `writing-pr-description` only when drafting a PR description.";
      }
    ]}
  '';

  makeInstructionsWithStyle =
    args: makeInstructions args + "\n## Output Style\n\n" + outputStyleRules;
in
{
  inherit makeInstructions makeInstructionsWithStyle outputStyleRules;
  inherit (subagents) formatSubagentAsMarkdown;
  subagentDefs = builtins.removeAttrs subagents [ "formatSubagentAsMarkdown" ];
}
