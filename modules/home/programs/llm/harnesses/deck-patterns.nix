# How the wezterm agent-deck plugin recognises each agent in a pane.
#
# The deck is the only status source for a harness whose notify is "scrape", so a
# harness missing from this file has no status on any channel. hermes was missing
# for exactly that reason and nothing reported it; runtime/default.nix now asserts
# this file covers the registry.
#
# These are Lua patterns, and the deck matches them against the full executable
# path, the basename, the argv string, and the pane title. An unanchored pattern
# therefore matches anywhere in a /nix/store path. Anchor every short name.
#
# status_patterns = [ ] means "use the plugin's shared default strings". Eleven
# agents declare that, because their busy and idle strings have not been observed
# in a pane. Declaring it makes the choice visible instead of a silent fallback.
{
  amp = {
    patterns = [ "amp" ];
    executable_patterns = [ "/amp$" ];
    argv_patterns = [ "^amp%s*$" ];
    title_patterns = [ "amp" ];
    status_patterns = [ ];
  };

  atomic = {
    patterns = [ "atomic" ];
    executable_patterns = [ "/atomic$" ];
    argv_patterns = [ "^atomic%s*$" ];
    title_patterns = [ "atomic" ];
    status_patterns = [ ];
  };

  claude = {
    patterns = [
      ".claude%-wrapped"
      "claude"
      "claude%-code"
    ];
    executable_patterns = [
      "@anthropic%-ai/claude%-code"
      "/claude%-code/"
      "/claude$"
      "claude"
    ];
    argv_patterns = [
      "@anthropic%-ai/claude%-code"
      "claude%-code"
      "^claude%s*$"
    ];
    title_patterns = [
      "claude code"
      "claude"
      ".claude%-wrapped"
    ];
    status_patterns = [ "esc to interrupt" ];
  };

  codex = {
    patterns = [ "codex" ];
    executable_patterns = [ "/codex$" ];
    argv_patterns = [ "^codex%s*$" ];
    title_patterns = [ "codex" ];
    status_patterns = [ "esc to interrupt" ];
  };

  copilot = {
    patterns = [ "copilot" ];
    executable_patterns = [
      "/copilot$"
      "copilot%-language%-server"
    ];
    argv_patterns = [ "^copilot%s*$" ];
    title_patterns = [ "copilot" ];
    status_patterns = [ ];
  };

  crush = {
    patterns = [ "crush" ];
    executable_patterns = [ "/crush$" ];
    argv_patterns = [ "^crush%s*$" ];
    title_patterns = [ "crush" ];
    status_patterns = [ ];
  };

  cursor = {
    patterns = [
      "cursor%-agent"
      "cursor"
    ];
    executable_patterns = [ "/cursor%-agent$" ];
    argv_patterns = [ "cursor%-agent" ];
    title_patterns = [ "cursor" ];
    status_patterns = [ ];
  };

  devin = {
    patterns = [ "devin" ];
    executable_patterns = [ "/devin$" ];
    argv_patterns = [ "^devin%s*$" ];
    title_patterns = [ "devin" ];
    status_patterns = [ ];
  };

  # "fx" is two characters, so every pattern here is anchored, as for "pi".
  # Unanchored it matches "fx" inside any /nix/store path.
  fx = {
    patterns = [ "^fx$" ];
    executable_patterns = [ "/fx$" ];
    argv_patterns = [ "^fx%s*$" ];
    title_patterns = [ "^fx$" ];
    status_patterns = [ ];
  };

  gemini = {
    patterns = [
      "antigravity"
      "agy"
      "gemini"
    ];
    executable_patterns = [
      "/agy$"
      "antigravity%-cli"
    ];
    argv_patterns = [ "^agy%s*$" ];
    title_patterns = [
      "antigravity"
      "gemini"
    ];
    status_patterns = [ ];
  };

  goose = {
    patterns = [
      "goose"
      "goosed"
    ];
    executable_patterns = [
      "/goose$"
      "/goosed$"
    ];
    argv_patterns = [ "^goose%s*$" ];
    title_patterns = [ "goose" ];
    status_patterns = [ ];
  };

  hermes = {
    patterns = [ "hermes" ];
    executable_patterns = [
      "/hermes$"
      "/hermes%-agent$"
    ];
    argv_patterns = [ "^hermes%s*$" ];
    title_patterns = [ "hermes" ];
    status_patterns = [ ];
  };

  opencode = {
    patterns = [ "opencode" ];
    executable_patterns = [
      "opencode%-darwin"
      "opencode%-linux"
      "%.opencode/bin/opencode"
      "/opencode%-ai/"
      "/opencode$"
    ];
    argv_patterns = [
      "bunx%s+opencode"
      "npx%s+opencode"
      "/opencode$"
    ];
    title_patterns = [ "opencode" ];
    status_patterns = [
      "enter confirm"
      "esc dismiss"
      "type your own answer"
    ];
  };

  # "pi" is two characters, so every pattern here is anchored. Unanchored it
  # matches "compile", "pip", and any /nix/store path holding either.
  pi = {
    patterns = [ "^pi$" ];
    executable_patterns = [
      "/pi$"
      "^pi$"
    ];
    argv_patterns = [ "^pi%s*$" ];
    title_patterns = [ "^pi$" ];
    status_patterns = [ ];
  };

  prime-agent = {
    patterns = [ "prime%-agent" ];
    executable_patterns = [ "/prime%-agent$" ];
    argv_patterns = [ "^prime%-agent%s*$" ];
    title_patterns = [ "prime agent" ];
    status_patterns = [ ];
  };
}
