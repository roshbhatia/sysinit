# Moved verbatim from flake.nix. The expression is unchanged: its derivation path
# is asserted equal to the pre-move baseline in
# openspec/changes/decompose-flake-checks/drv-baseline.json.
{
  pkgs,
  lib,
  inputs,
  system,
  notifyIcons,
  managedFile,
  ...
}:
# Behavioral gate for the destructive-command guard.
#
# The guard is the only mechanical floor under the agent's Bash tool
# while `dangerouslySkipPermissions` is on, and until this check existed
# `nix flake check` evaluates darwinConfigurations but skips building them,
# so a `home.file` source or a `${./asset}` that no longer exists stays
# invisible until `nh darwin build`. That is exactly how a file rename in
# this module reached a green check and then failed the switch: the path is
# inside a lazily-forced attribute, so evaluation never touches it.
#
# Cheap and deterministic: read every relative asset path out of the
# module's Nix sources and assert it resolves. It cannot catch a path built
# by string interpolation, which is why it reports the count it checked.
pkgs.runCommand "llm-asset-paths-resolve-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 - "${../modules/home/programs/llm}" <<'PY' | tee "$out"
  import pathlib, re, sys
  root = pathlib.Path(sys.argv[1])
  checked = missing = 0
  # Two shapes, because a rename breaks both. An asset read names a file
  # with an extension; a module import names a sibling directory or a
  # .nix file. The directory form is how `import ../lib` survived a move
  # up one level and still passed every check.
  patterns = [
      r'\.{1,2}/[A-Za-z0-9_./-]+\.(?:sh|py|ts|mdc|json|md)',
      r'import\s+(\.{1,2}/[A-Za-z0-9_./-]+)',
  ]
  for f in sorted(root.rglob("*.nix")):
      text = f.read_text()
      for pat in patterns:
          for m in re.finditer(pat, text):
              rel = m.group(1) if m.lastindex else m.group(0)
              checked += 1
              if not (f.parent / rel).exists():
                  print(f"FAIL: {f.relative_to(root)} reads {rel}, which does not exist", file=sys.stderr)
                  missing += 1
  if missing:
      print(f"{missing} unresolved asset path(s). A rename left a reader behind.", file=sys.stderr)
      sys.exit(1)
  print(f"OK: {checked} relative asset paths in the llm module all resolve")
  PY
''
