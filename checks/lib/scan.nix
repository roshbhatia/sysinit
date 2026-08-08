{ pkgs, lib }:
{
  mkScanCheck =
    {
      name,
      root,
      unit,
      tools ? [ ],
      findArgs,
      filter ? null,
      validate,
      requireNonEmpty ? [ ],
      hint ? null,
    }:
    pkgs.runCommand "${name}-check" { nativeBuildInputs = tools; } ''
      src=${root}
      found=0
      fail=0

      while IFS= read -r f; do
        [ -z "$f" ] && continue
        ${lib.optionalString (filter != null) filter}
        found=$((found + 1))
        if ! ${validate}; then
          echo "FAIL: $f" >&2
          fail=1
        fi
      done < <(find "$src" ${findArgs} | sort)

      ${lib.concatMapStrings (sub: ''
        if [ "$(find "$src/${sub.path}" ${sub.findArgs or findArgs} | wc -l)" -eq 0 ]; then
          echo "FAIL: ${sub.path} contributed no ${unit}." >&2
          echo "It moved or was renamed, and this check stopped covering it." >&2
          fail=1
        fi
      '') requireNonEmpty}

      if [ "$found" -eq 0 ]; then
        echo "FAIL: no ${unit} found under ${root}." >&2
        exit 1
      fi
      if [ "$fail" -ne 0 ]; then
        ${lib.optionalString (hint != null) "echo ${lib.escapeShellArg hint} >&2"}
        exit 1
      fi
      echo "OK: $found ${unit}" | tee "$out"
    '';
}
