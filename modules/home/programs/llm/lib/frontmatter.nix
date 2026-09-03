{ lib }:
let
  renderValue =
    indent: value:
    if builtins.isAttrs value then
      "\n"
      + lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: nested:
          let
            separator = if builtins.isAttrs nested then "" else " ";
          in
          "${indent}  ${name}:${separator}${renderValue "${indent}  " nested}"
        ) value
      )
    else
      builtins.toJSON value;

  renderFields =
    fields:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value:
        let
          separator = if builtins.isAttrs value then "" else " ";
        in
        "${name}:${separator}${renderValue "" value}"
      ) (lib.filterAttrs (_name: value: value != null) fields)
    );
in
rec {
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
          found = lib.lists.findFirstIndex (line: line == "---") null rest;
        in
        if found == null then throw "skill '${name}': frontmatter fence is never closed" else found;

      fmLines = lib.filter (line: line != "") (lib.take closeIdx rest);
      afterFence = lib.drop (closeIdx + 1) rest;
      bodyLines =
        if afterFence != [ ] && builtins.head afterFence == "" then
          builtins.tail afterFence
        else
          afterFence;

      toPair =
        line:
        let
          match = builtins.match "([^:]+): (.*)" line;
        in
        if match == null then
          throw "skill '${name}': frontmatter line is not a flat `key: value` pair: ${line}"
        else
          lib.nameValuePair (builtins.elemAt match 0) (builtins.elemAt match 1);
    in
    {
      attrs = builtins.listToAttrs (map toPair fmLines);
      body = lib.concatStringsSep "\n" bodyLines;
    };

  render = fields: ''
    ---
    ${renderFields fields}
    ---
  '';
}
