# overlays/hererocks.nix
# Purpose: provide hererocks python application.
{ ... }:

final: _prev: {
  hererocks = final.python3Packages.buildPythonApplication rec {
    pname = "hererocks";
    version = "0.25.1";
    pyproject = true;

    src = final.fetchFromGitHub {
      owner = "luarocks";
      repo = "hererocks";
      rev = version;
      hash = "sha256-B3AIQJP06YRGqEJLcbnhPmplRTu2+T7Rl7mlxR2qjXQ=";
    };

    build-system = [ final.python3Packages.setuptools ];

    # Tests require network access
    doCheck = false;

    meta = with final.lib; {
      description = "Tool for installing Lua and LuaRocks locally";
      homepage = "https://github.com/luarocks/hererocks";
      license = licenses.mit;
      mainProgram = "hererocks";
    };
  };
}
