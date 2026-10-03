{ lib, pkgs, ... }:
let
  rewriter = import ../../runtime/output-rewrite { inherit pkgs lib; };
  outputMod = pkgs.runCommand "claude-sysinit-output" { } ''
    cp -r ${./output-mod}/ "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/hooks/register.ts" --replace-fail '@rewriter@' '${lib.getExe rewriter}'
  '';
  prTracker = pkgs.fetchFromGitHub {
    owner = "sezaakgun";
    repo = "cc-pr-tracker";
    rev = "514da1edb4877cdb812ae1a25f79aa81fb6aa6db";
    hash = "sha256-uZJKVPlS2PTRU+UiziQyQ3TME5cC2cSn/gqKVLRypx8=";
  };
  mods = pkgs.fetchFromGitHub {
    owner = "galElmalah";
    repo = "claude-mods";
    rev = "b19a0f0d09bf214c010b15cc2849c0c1a11d7b0d";
    hash = "sha256-NGxg+oJ49FPfIM4ple0WbQeEXT25rnfIl5uqocUPi3g=";
  };
  aside = pkgs.fetchFromGitHub {
    owner = "JayDoubleu";
    repo = "aside";
    rev = "cf2b7562ae7b376cdcf9e2436a926aba77dc759f";
    hash = "sha256-Di/8NsOxaIkw/g4KmO0bFGqXfilXyRAapS4rY2oHyP4=";
  };
  plugins = {
    sysinit-output = outputMod;
    cc-pr-tracker = prTracker;
    claude-mermaid = "${mods}/claude-mermaid";
    claude-queue = "${mods}/claude-queue";
    inherit aside;
  };
in
{
  programs.claude-code.settings.env.CLAUDE_CODE_ENABLE_FUNCTION_HOOKS = "1";
  # Link whole roots because Claude rejects hooks outside a plugin's resolved directory.
  home.file = lib.mapAttrs' (
    name: source: lib.nameValuePair ".claude/skills/${name}" { inherit source; }
  ) plugins;
}
