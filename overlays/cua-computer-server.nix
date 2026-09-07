_final: prev:
let
  inherit (prev) lib;
  supportedLinux =
    prev.stdenv.hostPlatform.isLinux
    && (prev.stdenv.hostPlatform.isx86_64 || prev.stdenv.hostPlatform.isAarch64);

  pythonPackages = prev.python313.pkgs.overrideScope (
    pythonFinal: pythonPrev:
    let
      wheelPlatform =
        if prev.stdenv.hostPlatform.isx86_64 then
          "manylinux2014_x86_64.manylinux_2_17_x86_64"
        else
          "manylinux2014_aarch64.manylinux_2_17_aarch64";
      simpleWheel =
        {
          pname,
          version,
          hash,
          dependencies ? [ ],
          pythonImportsCheck,
        }:
        pythonPrev.buildPythonPackage {
          inherit
            pname
            version
            dependencies
            pythonImportsCheck
            ;
          format = "wheel";
          src = pythonPrev.fetchPypi {
            inherit pname version hash;
            format = "wheel";
            dist = "py3";
            python = "py3";
          };
        };
    in
    {
      protobuf = pythonPrev.buildPythonPackage {
        pname = "protobuf";
        version = "6.33.6";
        format = "wheel";
        src = pythonPrev.fetchPypi {
          pname = "protobuf";
          version = "6.33.6";
          format = "wheel";
          dist = "cp39";
          python = "cp39";
          abi = "abi3";
          platform = lib.removeSuffix ".manylinux_2_17_x86_64" (
            lib.removeSuffix ".manylinux_2_17_aarch64" wheelPlatform
          );
          hash =
            if prev.stdenv.hostPlatform.isx86_64 then
              "sha256-6dt+KS4Kt53RCNfxqU/jFgHOHuP3t54GkgQ0IwILBZM="
            else
              "sha256-4q+66bjhgl41KfiNUUdU4JQni7lercDhmXUc3ZougqI=";
        };
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = [ prev.stdenv.cc.cc.lib ];
        pythonImportsCheck = [ "google.protobuf" ];
      };

      grpcio = pythonPrev.buildPythonPackage {
        pname = "grpcio";
        version = "1.78.0";
        format = "wheel";
        src = pythonPrev.fetchPypi {
          pname = "grpcio";
          version = "1.78.0";
          format = "wheel";
          dist = "cp313";
          python = "cp313";
          abi = "cp313";
          platform = wheelPlatform;
          hash =
            if prev.stdenv.hostPlatform.isx86_64 then
              "sha256-c1444XaojOQYQMIbtJCYq2YXfGTIJCbiTgCCUAzGivU="
            else
              "sha256-jyrISQXRKRjk5VoW2heTnrY+Qz3BG2dyZ8NVaKpj/IQ=";
        };
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = [ prev.stdenv.cc.cc.lib ];
        dependencies = [ pythonFinal.typing-extensions ];
        pythonImportsCheck = [ "grpc" ];
      };

      fastmcp = simpleWheel {
        pname = "fastmcp";
        version = "3.2.0";
        hash = "sha256-5xq6PfFvhvVGpKnlEyYdMjO8ySvvDfpke6w/ozYj9oE=";
        dependencies =
          with pythonFinal;
          [
            authlib
            cyclopts
            exceptiongroup
            httpx
            jsonref
            jsonschema-path
            mcp
            openapi-pydantic
            opentelemetry-api
            packaging
            platformdirs
            py-key-value-aio
            pydantic
            pyperclip
            python-dotenv
            pyyaml
            rich
            uncalled-for
            uvicorn
            watchfiles
            websockets
          ]
          ++ pydantic.optional-dependencies.email
          ++ py-key-value-aio.optional-dependencies.filetree
          ++ py-key-value-aio.optional-dependencies.keyring
          ++ py-key-value-aio.optional-dependencies.memory;
        pythonImportsCheck = [ "fastmcp" ];
      };

      cua-core = pythonPrev.buildPythonPackage {
        pname = "cua-core";
        version = "0.3.1";
        pyproject = true;
        src = pythonPrev.fetchPypi {
          pname = "cua_core";
          version = "0.3.1";
          hash = "sha256-qPxCBJgbnVtgS9KjTeC7Qc+SYwnk3Z82TIJ3UKhkCNo=";
        };
        build-system = [ pythonFinal.pdm-backend ];
        dependencies = [ pythonFinal.posthog ];
        pythonImportsCheck = [ "cua_core" ];
      };

      cua-auto = pythonPrev.buildPythonPackage {
        pname = "cua-auto";
        version = "0.1.2";
        pyproject = true;
        src = pythonPrev.fetchPypi {
          pname = "cua_auto";
          version = "0.1.2";
          hash = "sha256-LFrGACsS0IsDlA4fjuVH7SBviyAoA4DcimiLCrSlbTQ=";
        };
        build-system = [ pythonFinal.hatchling ];
        dependencies = with pythonFinal; [
          pillow
          pynput
          pyperclip
          pywinctl
        ];
        pythonImportsCheck = [ "cua_auto" ];
      };

      cua-computer-server = pythonPrev.buildPythonApplication {
        pname = "cua-computer-server";
        version = "0.3.42";
        pyproject = true;
        src = pythonPrev.fetchPypi {
          pname = "cua_computer_server";
          version = "0.3.42";
          hash = "sha256-uCLoUgAC/F2Lx9TX1DDUYdRrmAtPbflE+f4qDcmPC1A=";
        };
        build-system = [ pythonFinal.pdm-backend ];
        dependencies =
          with pythonFinal;
          [
            aiohttp
            cua-auto
            cua-core
            fastapi
            fastmcp
            grpcio
            pillow
            playwright
            protobuf
            pydantic
            pynput
            pyperclip
            python-xlib
            pywinctl
            uvicorn
            websockets
          ]
          ++ uvicorn.optional-dependencies.standard;
        env.PYNPUT_BACKEND = "dummy";
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath [
            prev.xrandr
            prev.xset
          ])
        ];
        pythonImportsCheck = [ "computer_server" ];
        meta = {
          description = "Host-side server for the Cua computer-use interface";
          homepage = "https://github.com/trycua/cua";
          license = lib.licenses.mit;
          mainProgram = "cua-computer-server";
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        };
      };
    }
  );
in
lib.optionalAttrs supportedLinux {
  inherit (pythonPackages) cua-computer-server;
}
