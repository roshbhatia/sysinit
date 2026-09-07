{
  lib,
  pkgs,
  ...
}:

pkgs.runCommand "cua-computer-server-test" { } ''
  server=${lib.getExe pkgs.cua-computer-server}
  wrapped="$(dirname "$server")/.cua-computer-server-wrapped"

  test -x "$server"
  test "$(basename "$server")" = cua-computer-server
  test -x "$wrapped"
  grep -q 'python3.13-evdev-' "$wrapped"
  grep -q '${pkgs.xrandr}/bin' "$server"
  grep -q '${pkgs.xset}/bin' "$server"
  ! grep -Eq '/uv|uv run|uvx' "$server" "$wrapped"

  grep -q 'Restart = "on-failure"' ${../modules/home/programs/llm/mcp-servers.nix}
  grep -q 'RestartSec = 10' ${../modules/home/programs/llm/mcp-servers.nix}
  grep -q 'StartLimitBurst = 3' ${../modules/home/programs/llm/mcp-servers.nix}
  grep -q 'StartLimitIntervalSec = 300' ${../modules/home/programs/llm/mcp-servers.nix}

  touch "$out"
''
