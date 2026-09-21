final: prev:
let
  revision = "a48dde04f31377d99fd22507f84c7fcc694d4283";
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
          hash = "sha256-RR/jCE0KmKnPHS8MzWs1E6H5OgzK1se2Hhwh3QXeRaw=";
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
