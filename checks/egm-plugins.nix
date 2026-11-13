{ pkgs, home }:
pkgs.runCommand "egm-plugin-bundle" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  mkdir -p "$out"
  ln -s ${home.programs.codex.marketplaces.egm} "$out/bundle"
  ln -s ${home.home.file.".claude/skills/egm".source} "$out/claude"
  ln -s ${home.home.file.".codex/config.toml".source} "$out/config.toml"
  python3 - "$out" <<'PY'
  from pathlib import Path
  import json
  import sys
  import tomllib

  output = Path(sys.argv[1])
  settings = tomllib.loads((output / "config.toml").read_text())
  assert settings["plugins"]["egm@egm"]["enabled"]
  marketplace = settings["marketplaces"]["egm"]
  assert marketplace["source_type"] == "local", marketplace
  assert Path(marketplace["source"]).resolve() == (output / "bundle").resolve()
  skills = {"egm-bootstrap", "egm-brainstorm", "egm-draft", "egm-drift-report", "egm-resolve", "egm-review", "egm-review-loop"}
  for root in (output / "bundle", output / "claude"):
      for name in skills:
          assert (root / "skills" / name / "SKILL.md").is_file(), name
      for relative in ("agents", "resources/document_standards", "docs/codex.md"):
          assert (root / relative).exists(), relative
  claude = (output / "claude").resolve()
  manifest = json.loads((claude / ".claude-plugin/plugin.json").read_text())
  for agent in manifest["agents"]:
      assert (claude / agent).resolve().is_relative_to(claude), agent
  print("Pinned EGM marketplace, complete bundles and native enablement verified")
  PY
''
