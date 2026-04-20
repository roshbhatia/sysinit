{ pkgs, ... }:
{
  # Config managed by sysinit.agents; binary only here.
  home.packages = [ pkgs.gemini-cli ];
}
