_:

final: _prev: {
  sheets = final.buildGoModule {
    pname = "sheets";
    version = "0.2.0";

    src = final.fetchFromGitHub {
      owner = "maaslalani";
      repo = "sheets";
      rev = "v0.2.0";
      hash = "sha256-sRJ1rqtxc4axAkVavxSR2afdvxCAjJdK2mBWnt+nzW0=";
    };

    vendorHash = "sha256-WWtAt0+W/ewLNuNgrqrgho5emntw3rZL9JTTbNo4GsI=";

    doCheck = false;

    meta = with final.lib; {
      description = "Terminal based spreadsheet tool";
      homepage = "https://github.com/maaslalani/sheets";
      license = licenses.mit;
      mainProgram = "sheets";
    };
  };
}
