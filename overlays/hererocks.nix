{ ... }:

final: _prev:
let
  sources = final.nvfetcherSources.hererocks;
in
{
  hererocks = final.python3Packages.buildPythonApplication {
    pname = "hererocks";
    inherit (sources) version src;
    pyproject = true;

    build-system = [ final.python3Packages.setuptools ];

    doCheck = false;

    meta = with final.lib; {
      description = "Tool for installing Lua and LuaRocks locally";
      homepage = "https://github.com/luarocks/hererocks";
      license = licenses.mit;
      mainProgram = "hererocks";
    };
  };
}
