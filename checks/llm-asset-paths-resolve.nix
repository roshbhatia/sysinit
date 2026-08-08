{
  pkgs,
  ...
}:
pkgs.runCommand "llm-asset-paths-resolve-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 - "${../modules/home/programs/llm}" <<'PY' | tee "$out"
  import pathlib, re, sys
  root = pathlib.Path(sys.argv[1])
  checked = missing = 0
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
