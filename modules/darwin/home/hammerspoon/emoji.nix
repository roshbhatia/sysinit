{ pkgs }:

# One dataset for both hosts. arrakis reads emoji through elephant's `symbols`
# provider, which embeds the Unicode CLDR annotation files; this derivation
# reads those same files out of elephant's source rather than fetching CLDR a
# second time, so `:sparkles` cannot resolve to different characters or carry
# different names on the two machines. If elephant moves the files, this build
# fails on the missing path instead of drifting.
#
# `variations.txt` is applied the way elephant applies it: a codepoint listed
# there is emitted with U+FE0F appended, which is what makes it render as an
# emoji rather than as text.
pkgs.runCommand "sysinit-emoji.json"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    src = pkgs.elephant.src;
  }
  ''
    python3 ${./emoji-data.py} "$src" "$out"
  ''
