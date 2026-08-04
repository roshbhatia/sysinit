{
  pkgs,
  lib,
  ...
}:
# The skill sources moved from Nix strings to SKILL.md files. This
# asserts the move changed no rendered byte, which is the only claim
# that matters: 2,113 lines of prose only git holds a copy of.
#
# It is a real check rather than a one-time diff because the frontmatter
# reader and the include expander are now load-bearing: a regression in
# either silently reshapes every skill the fleet loads.
let
  s = import ../modules/home/programs/llm/skills/render.nix { inherit pkgs; };
  reg = import ../modules/home/programs/llm/skills { inherit pkgs lib; };
  toolSources = import ../modules/home/programs/llm/skills/tool-sources.nix;
in
pkgs.runCommand "skill-render-shape-check" { } (
  let
    claudeOne = builtins.head (lib.attrValues s.allSkills);
  in
  ''
    fail=0
    # Every skill renders for both harnesses.
    n_claude=${toString (lib.length (lib.attrNames s.allSkills))}
    n_amp=${toString (lib.length (lib.attrNames s.ampSkills))}
    n_reg=${toString (lib.length (lib.attrNames reg))}
    [ "$n_claude" = "$n_reg" ] || { echo "FAIL: claude renders $n_claude of $n_reg skills" >&2; fail=1; }
    [ "$n_amp" = "$n_reg" ]    || { echo "FAIL: amp renders $n_amp of $n_reg skills" >&2; fail=1; }

    # The include expander must leave no placeholder behind. A
    # surviving {{...}} means a skill ships a literal template to the
    # model, which reads as an instruction it cannot satisfy.
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (n: f: ''
        if grep -qE '\{\{[a-zA-Z_]+\}\}' ${f}; then
          echo "FAIL: rendered claude/${n} still contains a {{placeholder}}" >&2
          fail=1
        fi
      '') s.allSkills
    )}

    # Frontmatter must survive as frontmatter, not become body text.
    head -1 ${claudeOne} | grep -qx -- --- || { echo "FAIL: render lost its frontmatter fence" >&2; fail=1; }

    # A skill that owns a PATH command keeps that command's source at
    # its own top level, which skills/default.nix does not install. The
    # asymmetry is load-bearing: moving such a script into scripts/
    # would ship a second copy into all four rendered trees, where an
    # agent could run it instead of the wrapper that has the runtime
    # deps. Nothing else asserted this, so the placement was one edit
    # away from silently reverting.
    #
    # The names come from skills/tool-sources.nix, the same list
    # skill-tools.nix builds from, so a third tool is covered without a
    # second edit here.
    installed="${lib.concatStringsSep " " (lib.attrNames s.skillExtraFiles)}"
    for src in ${lib.concatStringsSep " " (lib.attrValues toolSources)}; do
      for extra in $installed; do
        if [ "$extra" = "$src" ]; then
          echo "FAIL: $extra is installed into every skill tree, but a PATH command already provides it." >&2
          echo "Keep a skill-owned CLI's source at the skill's top level; see llm/skill-tools.nix." >&2
          fail=1
        fi
      done
    done

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: $n_reg skills render for both harnesses with no stray placeholder" > "$out"
  ''
)
