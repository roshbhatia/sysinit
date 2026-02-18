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
      hash = "sha256-y28MTFncy5oD57jpY6AN+X/58OzY3ae3rSL236rfuL0=";
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
