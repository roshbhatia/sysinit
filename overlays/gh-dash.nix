final: prev:
let
  revision = "b547ecfb9811afe21f6eed3f041125f9a2d48565";
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
          hash = "sha256-FcSsGZSxzgmb8Vr1Mo6eciioZiSc4JkUDnWa5UsiqpM=";
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
