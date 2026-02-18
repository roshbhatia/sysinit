{ ... }:

final: _prev: {
  gomvp = final.buildGoModule rec {
    pname = "gomvp";
    version = "0.0.4";

    src = final.fetchFromGitHub {
      owner = "abenz1267";
      repo = "gomvp";
      rev = "v${version}";
      hash = "sha256-dXjI+nItJCAGKxyC9tX11hxWHCP+NgXtTYtm5+6dqDU=";
    };

    vendorHash = "sha256-OB8pkD7Y/lNJvVxPdPei48JMaAf+bgK1Na8G7bqlLak=";

    meta = with final.lib; {
      description = "Refactoring tool for moving Go packages";
      homepage = "https://github.com/abenz1267/gomvp";
      license = licenses.mit;
      mainProgram = "gomvp";
    };
  };
}
