_:

final: prev:
let
  version = "0.0.1779345702-g49e69d";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-${version}.tgz";
    hash = "sha256-tK0kfRHs6V7Pl/1htuN7T9xvzDcy7LunSgUh3DC2rPA="; # autoupdate:src-hash
  };
in
{
  amp-cli = prev.amp-cli.overrideAttrs (old: {
    inherit version src;
    postPatch = ''
      cp ${./amp-cli-package-lock.json} package-lock.json

      cat > package.json <<EOF
      {
        "name": "amp-cli",
        "version": "0.0.0",
        "license": "UNLICENSED",
        "dependencies": {
          "@sourcegraph/amp": "${version}"
        },
        "bin": {
          "amp": "./bin/amp-wrapper.js"
        }
      }
      EOF

      mkdir -p bin

      cat > bin/amp-wrapper.js << EOF
      #!/usr/bin/env node
      import('@sourcegraph/amp/dist/main.js')
      EOF
      chmod +x bin/amp-wrapper.js
    '';
    npmDeps = prev.fetchNpmDeps {
      name = "amp-cli-${version}-npm-deps";
      inherit src;
      postPatch = ''
        cp ${./amp-cli-package-lock.json} package-lock.json

        cat > package.json <<EOF
        {
          "name": "amp-cli",
          "version": "0.0.0",
          "license": "UNLICENSED",
          "dependencies": {
            "@sourcegraph/amp": "${version}"
          },
          "bin": {
            "amp": "./bin/amp-wrapper.js"
          }
        }
        EOF
      '';
      hash = "sha256-18wa5i+e+wbTX/47I0MxJAkYl9o3/S0t2h/DSo+dsMI="; # autoupdate:npm-deps-hash
    };
  });
}
