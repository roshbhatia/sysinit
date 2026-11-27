{ pkgs, ... }:
{
  home.packages = [
    pkgs.agent-diff
    pkgs.agent-review-link
  ];
}
