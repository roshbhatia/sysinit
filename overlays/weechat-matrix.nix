{
  ...
}:

final: prev:
let
  # Pin to latest master branch commit
  version = "unstable-2023-07-23";
  rev = "feae9fda26ea9de98da9cd6733980a203115537e";
  sha256 = "sha256-flv1XF0tZgu3qoMFfJZ2MzeHYI++t12nkq3jJkRiCQ0=";
in
{
  weechatScripts = prev.weechatScripts // {
    weechat-matrix = prev.weechatScripts.weechat-matrix.overrideAttrs (_old: {
      inherit version;

      src = final.fetchFromGitHub {
        owner = "poljar";
        repo = "weechat-matrix";
        inherit rev sha256;
      };

      # Remove patches that are already applied upstream
      patches = [ ];

      # Update propagatedBuildInputs to match current dependencies
      propagatedBuildInputs = with final.python3Packages; [
        matrix-nio
        aiohttp
        requests
        python-magic
        pillow
        pyopenssl
        webcolors
        atomicwrites
        attrs
        pygments
        logbook
        cffi
      ];
    });
  };
}
