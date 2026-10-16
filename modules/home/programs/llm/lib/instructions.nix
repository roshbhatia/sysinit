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
      rule = "Read the applicable `AGENTS.md`, active changes, and relevant local lessons before editing.";
      reason = "Search narrowly, then read the needed sections; repository facts have priority over general habits.";
      bad = "Assume the build command from another repository.";
      good = "Read `AGENTS.md`, then use the command it defines.";
    }
    {
      rule = "Load a skill when its domain matches the task.";
      reason = "Keep global instructions for shared decisions; load domain workflows and repository details only when needed.";
      bad = "Carry every commit, review, and documentation rule in global context.";
      good = "Load `writing-commit-message` before you create a commit.";
    }
    {
      rule = "Make the smallest complete change that meets the request, using existing patterns.";
      reason = "Add abstractions, dependencies, and adjacent refactors only when the requested behavior needs them.";
      bad = "Build a generic framework to fix one call site.";
      good = "Fix the affected path and its callers; leave unrelated cleanup for its own task.";
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
      rule = "Reuse the selected task worktree. Load `feature-based-session-manager` before creating or cleaning worktrees.";
      reason = "One lifecycle owner prevents duplicate checkouts and conflicting cleanup.";
      bad = "Create another nested checkout inside a harness-owned worktree for the same task.";
      good = "Use the selected checkout, isolate concurrent writers, and register external worktrees by reference when grouping them.";
    }
    {
      rule = "On an unexpected error, preserve the evidence and investigate before the next dependent step.";
      reason = "Change the approach when evidence changes; repeated retries or bypasses do not fix the cause.";
      bad = "Retry with a bypass flag after an unknown build failure.";
      good = "Read the failing log, fix the cause, then rerun the same check.";
    }
    {
      rule = "Inspect the complete diff and verify the changed behavior with checks proportionate to its risk.";
      reason = "Run required repository gates, then test the affected flow and relevant failure cases; report checks not run.";
      bad = "Report success after the compiler exits zero.";
      good = "Inspect the diff, run the suite, and test the changed command.";
    }
    {
      rule = "Do not add type suppressions, emojis, or vendored upstream updates without explicit permission.";
      reason = "These changes hide type failures or alter owner-managed content.";
      bad = "Add `any` to silence a type error or refresh a vendor tree incidentally.";
      good = "Fix the type and leave upstream vendor drift for its sync command.";
    }
    {
      rule = "Distinguish observations, inferences, and unverified claims.";
      reason = "Report the result with its evidence and limits; never claim a test, deployment, or approval that did not happen.";
      bad = "Call a deployment complete because its build passed.";
      good = "State that the build passed and activation remains unverified.";
    }
  ];

  autonomyRules = ''
    ## Decisions and approval

    Take reversible steps within the request, then show the result. Use inspection or a bounded check to resolve factual uncertainty.
    Ask before irreversible or hard-to-reverse effects unless the user already authorized that action and scope.
    Reversibility alone does not authorize unrelated work or external messages.

    Reserve questions for missing decisions that materially change the outcome, including taste and product choices.
    Ask one decision at a time, give a recommendation, and use the harness's question tool when available.
    State a supported objection when the requested approach would cause a problem.

    Keep approval valid for the work it covers; do not ask again at each step.
    When delegating, include the user's exact authorization and its scope for the {{agent}}.
    Revisit approval only when new evidence changes the action, scope, or consequences; explain what changed.
    Investigate failed checks and fix them within the approved scope before proceeding.
  '';

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

        ## ${section.title}

        ${section.body}
      '';
      extras = builtins.concatStringsSep "\n" (map extraText extraSections);
      base = ''
        ${autonomyRules}

        ## Working rules

        ${contextRules}
        ${loaderNote}

        ## Shared tasks

        Taskwarrior is the durable todo context shared by agents on this machine.
        Before multi-step work, read the `taskwarrior` skill and check relevant tasks.
        Record agreed work, blockers, and verified completion there. Use UUIDs across sessions.
        Follow host-specific instructions for imported tasks and external synchronization.
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
        bad = ''
          ## Result

          - Status: successful
          - Outcome: all three tests passed
        '';
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

  makeInstructionsWithStyle = args: ''
    ${makeInstructions args}
    ## Output Style

    ${outputStyleRules}
  '';
in
{
  inherit makeInstructions makeInstructionsWithStyle outputStyleRules;
  inherit (subagents) formatSubagentAsMarkdown;
  subagentDefs = builtins.removeAttrs subagents [ "formatSubagentAsMarkdown" ];
}
