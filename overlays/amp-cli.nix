_:

final: prev:
let
  version = "0.0.1778790766-g60d194";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-${version}.tgz";
    hash = "sha256-eFEYFDveWWQBWRE2C6uAkoZ3xGTWjoifh70EWg3kU+o="; # autoupdate:src-hash
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
      hash = "sha256-i4gAV466+OhCk34y1bNLe0XeNIIyGHKI3F5tCAsfeNA="; # autoupdate:npm-deps-hash
    };
  });
}
