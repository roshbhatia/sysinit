final: prev:
let
  revision = "15f86d17b1a3f7217d97817b008176df8d3b7968";
  version = "4.25.2-roshbhatia-2026-09-21";
in
{
  sysinit-gh-dash =
    (prev.gh-dash.override { buildGoModule = final.buildGo127Module; }).overrideAttrs
      (old: {
        inherit version;
        src = final.fetchFromGitHub {
          owner = "roshbhatia";
          repo = "gh-dash";
          rev = revision;
          hash = "sha256-KN4AkWFdJQ7Q5/R22zlypnMhDhoR8LFa1NS8jkE8tYA=";
        };
        vendorHash = "sha256-edFzZpM1DIwFnMLQlOuh5c8CFzYm3X2YheGFDgOLZ0I=";
        ldflags = [
          "-s"
          "-w"
          "-X github.com/dlvhdr/gh-dash/v4/cmd.Version=${version}"
          "-X github.com/dlvhdr/gh-dash/v4/cmd.Commit=${revision}"
        ];
        meta = old.meta // {
          homepage = "https://github.com/roshbhatia/gh-dash";
          changelog = "https://github.com/roshbhatia/gh-dash/commit/${revision}";
        };
      });
}
