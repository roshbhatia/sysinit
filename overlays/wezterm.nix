{ ... }:

_final: prev:
{
  wezterm = prev.wezterm.overrideAttrs (_old: {
    src = prev.fetchFromGitHub {
      owner = "roshbhatia";
      repo = "wezterm";
      rev = "main";
      hash = "sha256-ANucxjNFMUfoqlTAGILyWuBekgdRRFFXgrEB/mibjDE=";
    };
  });
}
// prev.lib.optionalAttrs (prev ? "wezterm-nightly") {
  "wezterm-nightly" = prev."wezterm-nightly".overrideAttrs (_old: {
    src = prev.fetchFromGitHub {
      owner = "roshbhatia";
      repo = "wezterm";
      rev = "main";
      hash = "sha256-ANucxjNFMUfoqlTAGILyWuBekgdRRFFXgrEB/mibjDE=";
    };
  });
}
// prev.lib.optionalAttrs (prev ? "wezterm-nightly") {
  "wezterm-nightly" = prev."wezterm-nightly".overrideAttrs (_old: {
    src = prev.fetchFromGitHub {
      owner = "roshbhatia";
      repo = "wezterm";
      rev = "main";
      hash = prev.lib.fakeHash;
    };
  });
}
