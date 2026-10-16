final: _prev: {
  sheets = final.buildGoModule {
    pname = "sheets";
    version = "0.3.0";

    src = final.fetchFromGitHub {
      owner = "maaslalani";
      repo = "sheets";
      rev = "v0.3.0";
      hash = "sha256-xDu+jbWH7ubXC6ImvkRVgPI0OHAaUQ60sELDJN8hY1M=";
    };

    vendorHash = "sha256-X7bfALH9mM15HP6SM60CFIG1rm4Ma6LEh2p7z5LNW64=";

    doCheck = false;

    meta = with final.lib; {
      description = "Terminal based spreadsheet tool";
      homepage = "https://github.com/maaslalani/sheets";
      license = licenses.mit;
      mainProgram = "sheets";
    };
  };
}
