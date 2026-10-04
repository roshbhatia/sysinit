final: prev: {
  jankyborders =
    if prev.stdenv.hostPlatform.isDarwin then
      (prev.jankyborders.override {
        # LLVM 21's ASan deadlocks on recent macOS: llvm/llvm-project#182943.
        stdenv = final.llvmPackages_23.stdenv;
      }).overrideAttrs
        (old: {
          version = "${old.version}-sysinit.1";
          src = prev.jankyborders.src;

          patches = (old.patches or [ ]) ++ [
            (final.fetchurl {
              name = "jankyborders-ipc-allocation-safety.patch";
              url = "https://github.com/qeesung/JankyBorders/commit/6563b4e3ac208a0a32796448c4d849f1f34564db.patch";
              hash = "sha256-3dk3HHPw0+jV/7YYPswbwo66Hx7szgLUyXNZUDUwGJs=";
            })
            (final.fetchurl {
              name = "jankyborders-ipc-compatibility.patch";
              url = "https://github.com/qeesung/JankyBorders/commit/a896b52ef53f00e76348af34adaa0672eb62d737.patch";
              hash = "sha256-J/Odgn9R5gQXStU6Y4W3MXhBn6/0wuv7GaWmQeem2Xw=";
            })
            (final.fetchurl {
              name = "jankyborders-mach-port-ownership.patch";
              url = "https://github.com/qeesung/JankyBorders/commit/924c0c97360c4016dc6f3d6d3fa0e294652c20ce.patch";
              hash = "sha256-x6nQ+pDxe+zqqCjn6a+mbI64Sv9+4JCukj58X1slqI8=";
            })
            ./mission-control.patch
          ];

          postPatch = (old.postPatch or "") + ''
            substituteInPlace src/main.c \
              --replace-fail 'borders-v%d.%d.%d\n' 'borders-v%d.%d.%d-sysinit.1\n'
          '';

          doCheck = true;
          nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ final.llvmPackages_23.llvm ];
          checkPhase = ''
            runHook preCheck
            make test test-sanitize
            clang -std=c99 -O1 -g -Isrc -fsanitize=address,undefined \
              -fno-omit-frame-pointer tests/mission_control_test.c \
              -o bin/mission_control_test -framework AppKit -framework CoreVideo
            ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=halt_on_error=1 ./bin/mission_control_test
            ./bin/borders --version | grep -Fx 'borders-v${old.version}-sysinit.1'
            runHook postCheck
          '';
        })
    else
      prev.jankyborders;
}
