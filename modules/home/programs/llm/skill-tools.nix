{ pkgs, ... }:
{
  # `worker` and `citelock` are names the binary installs itself: the skill and the
  # pre-commit hook both spell them, and neither needs a shell in front.
  home.packages = [ pkgs.utils ];
}
