# Reads the flat YAML frontmatter a SKILL.md carries.
#
# Deliberately not a YAML parser. The accepted grammar is one `key: value` per
# line, no nesting, no lists, no block scalars, because that is the whole of
# what a skill declares and because the renderer that ships the same files reads
# them with `yq`. Two parsers agreeing is only achievable when the grammar is
# small enough to state in a sentence.
#
# A key may not contain a colon, so the first `: ` splits. That matters: a
# description routinely contains colons and must survive intact.
{ lib }:
rec {
  # Expands `<!-- include: <file> [k=v ...] -->` against a directory of shared
  # fragments, substituting `{{k}}` in the fragment with v.
  #
  # This exists because two skills share a block whose whole purpose is that it
  # cannot drift between them. Flattening the source to per-skill Markdown would
  # have duplicated it and silently dropped that guarantee. The placeholder
  # convention is the one `lib/vocab.nix` already uses.
  expandIncludes =
    { name, sharedDir }:
    body:
    let
      lines = lib.splitString "\n" body;
      expand =
        line:
        let
          m = builtins.match "<!-- include: ([^ ]+)(.*) -->" line;
        in
        if m == null then
          line
        else
          let
            file = builtins.elemAt m 0;
            argStr = builtins.elemAt m 1;
            path = sharedDir + "/${file}";
            text =
              if builtins.pathExists path then
                builtins.readFile path
              else
                throw "skill '${name}': include names a missing fragment: ${file}";
            pairs = lib.filter (s: s != "") (lib.splitString " " argStr);
            sub =
              acc: pair:
              let
                kv = builtins.match "([^=]+)=(.*)" pair;
              in
              if kv == null then
                throw "skill '${name}': include argument is not k=v: ${pair}"
              else
                builtins.replaceStrings [ "{{${builtins.elemAt kv 0}}}" ] [ (builtins.elemAt kv 1) ] acc;
            filled = lib.foldl' sub text pairs;
            # Bracket expressions, not `\{`. A backslash-escaped brace is accepted
            # by the regex library Nix links on Darwin and REJECTED by the one it
            # links on Linux, which failed every NixOS evaluation with "invalid
            # regular expression" while every Darwin build stayed green. `nix flake
            # check` cannot see this from a Mac: it omits the Linux systems, so the
            # divergence is invisible until a NixOS host evaluates. `[{]` is one
            # literal brace under every grammar involved.
            leftover = builtins.match ".*[{][{][a-zA-Z_]+[}][}].*" filled;
          in
          if leftover != null then
            throw "skill '${name}': include of ${file} leaves an unsubstituted {{placeholder}}"
          else
            lib.removeSuffix "\n" filled;
    in
    lib.concatStringsSep "\n" (map expand lines);

  parse =
    name: text:
    let
      lines = lib.splitString "\n" text;

      openOk = lines != [ ] && builtins.head lines == "---";
      rest =
        if openOk then
          builtins.tail lines
        else
          throw "skill '${name}': SKILL.md must open with a --- frontmatter fence";

      closeIdx =
        let
          found = lib.lists.findFirstIndex (l: l == "---") null rest;
        in
        if found == null then throw "skill '${name}': frontmatter fence is never closed" else found;

      fmLines = lib.filter (l: l != "") (lib.take closeIdx rest);
      afterFence = lib.drop (closeIdx + 1) rest;
      # The writer emits exactly one blank line after the fence; drop it so the
      # body round-trips byte-identically.
      bodyLines =
        if afterFence != [ ] && builtins.head afterFence == "" then
          builtins.tail afterFence
        else
          afterFence;

      toPair =
        line:
        let
          m = builtins.match "([^:]+): (.*)" line;
        in
        if m == null then
          throw "skill '${name}': frontmatter line is not a flat `key: value` pair: ${line}"
        else
          lib.nameValuePair (builtins.elemAt m 0) (builtins.elemAt m 1);
    in
    {
      attrs = builtins.listToAttrs (map toPair fmLines);
      body = lib.concatStringsSep "\n" bodyLines;
    };
}
