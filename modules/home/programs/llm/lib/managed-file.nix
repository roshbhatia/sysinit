{ lib }:
let
  mergeProgram = ''
    def show($v): ($v | tojson) as $s
      | if ($s | length) > 160 then ($s[0:160] + " ...") else $s end;

    def m3($p; $b; $d; $n):
      if $d == $n then $n
      elif $d == $b then $n
      elif $n == $b then $d
      elif (($b | type) == "object") and (($d | type) == "object") and (($n | type) == "object") then
        ([($b | keys_unsorted[]), ($d | keys_unsorted[]), ($n | keys_unsorted[])] | unique) as $ks
        | reduce $ks[] as $k (
            {};
            ($b | has($k)) as $hb
            | ($d | has($k)) as $hd
            | ($n | has($k)) as $hn
            | ($p + [$k]) as $q
            | if $hb and $hd and $hn then
                .[$k] = m3($q; $b[$k]; $d[$k]; $n[$k])
              elif $hb and $hd and ($hn | not) then
                if $d[$k] == $b[$k] then . else .[$k] = $d[$k] end
              elif $hb and ($hd | not) and $hn then
                if $n[$k] == $b[$k] then .
                else error("conflict at ." + ($q | join(".")) + ": the live file deleted this key and the Nix content changed it.\n  base: " + show($b[$k]) + "\n  live: (absent)\n  nix:  " + show($n[$k])) end
              elif ($hb | not) and $hd and $hn then
                if $d[$k] == $n[$k] then .[$k] = $n[$k]
                else error("conflict at ." + ($q | join(".")) + ": the live file and the Nix content each added a different value.\n  base: (absent)\n  live: " + show($d[$k]) + "\n  nix:  " + show($n[$k])) end
              elif ($hb | not) and $hd and ($hn | not) then
                .[$k] = $d[$k]
              elif ($hb | not) and ($hd | not) and $hn then
                .[$k] = $n[$k]
              else . end
          )
      else
        error("conflict at ." + ($p | join(".")) + ": the base, the live file, and the Nix content all differ.\n  base: " + show($b) + "\n  live: " + show($d) + "\n  nix:  " + show($n))
      end;

    m3([]; .[0]; .[1]; .[2])
  '';

  formats = [
    "json"
    "yaml"
    "toml"
  ];

  fileDefaults = {
    enable = true;
    content = { };
    contentFile = null;
    format = "json";
    schema = null;
    enforce = [ ];
    retire = [ ];
    createIfMissing = true;
  };

  mkTestFile = attrs: fileDefaults // attrs;

  nixRender = ''
    def nixkey: if test("^[a-zA-Z_][a-zA-Z0-9_'-]*$") then . else tojson end;
    def nixval($ind):
      ($ind + "  ") as $i
      | if type == "object" then
          if length == 0 then "{ }"
          else "{\n" + ([to_entries[] | $i + (.key | nixkey) + " = " + (.value | nixval($i)) + ";"] | join("\n")) + "\n" + $ind + "}"
          end
        elif type == "array" then
          if length == 0 then "[ ]"
          else "[\n" + ([.[] | $i + nixval($i)] | join("\n")) + "\n" + $ind + "]"
          end
        elif type == "string" then tojson
        elif type == "boolean" then (if . then "true" else "false" end)
        elif type == null then "null"
        else tostring
        end;
  '';

  mkCapture =
    { pkgs, files }:
    let
      enabled = lib.filterAttrs (_: f: f.enable) files;
      diffDefs = ''
        def changedTree($b; $d):
          reduce ($d | keys_unsorted[]) as $k ({};
            if ($b | has($k) | not) then .
            elif $b[$k] == $d[$k] then .
            elif (($b[$k] | type) == "object") and (($d[$k] | type) == "object") then
              (changedTree($b[$k]; $d[$k])) as $s
              | if ($s | length) == 0 then . else .[$k] = $s end
            else .[$k] = $d[$k]
            end);
        def addedTree($b; $d):
          reduce ($d | keys_unsorted[]) as $k ({};
            if ($b | has($k) | not) then .[$k] = $d[$k]
            elif (($b[$k] | type) == "object") and (($d[$k] | type) == "object") then
              (addedTree($b[$k]; $d[$k])) as $s
              | if ($s | length) == 0 then . else .[$k] = $s end
            else .
            end);
      '';
      emit = fn: ''
        .[0] as $b | .[1] as $d
        | ${fn}($b; $d)
        | if length == 0 then "" else nixval("") end'';
      changedFile = pkgs.writeText "capture-changed.jq" (nixRender + diffDefs + emit "changedTree");
      addedFile = pkgs.writeText "capture-added.jq" (nixRender + diffDefs + emit "addedTree");
      mkCase =
        name: f:
        "${lib.escapeShellArg name}) capture ${lib.escapeShellArg name} ${lib.escapeShellArg f.path} ${f.format} ;;";
    in
    pkgs.writeShellApplication {
      name = "sysinit-llm-capture";
      runtimeInputs = [
        pkgs.jq
        pkgs.yq-go
      ];
      text = ''
        names=${lib.escapeShellArg (lib.concatStringsSep " " (builtins.attrNames enabled))}

        usage() {
          echo "usage: sysinit-llm-capture [--all] <harness>" >&2
          echo "  --all  also list values that exist only in the live file" >&2
          echo "harnesses with a managed file:" >&2
          for n in $names; do echo "  $n" >&2; done
        }

        to_json() {
          case "$2" in
            json) jq '.' "$1" ;;
            yaml) yq -p yaml -o json '.' "$1" ;;
            toml) yq -p toml -o json '.' "$1" ;;
          esac
        }

        capture() {
          local name="$1" rel="$2" fmt="$3"
          local target="$HOME/$rel" base_name sidecar
          base_name="$(basename "$target")"
          case "$base_name" in
            .*) sidecar="$(dirname "$target")/$base_name.nix-base" ;;
            *) sidecar="$(dirname "$target")/.$base_name.nix-base" ;;
          esac

          if [ ! -f "$target" ]; then
            echo "sysinit-llm-capture: $rel does not exist yet." >&2
            return 1
          fi
          if [ ! -f "$sidecar" ]; then
            echo "sysinit-llm-capture: $rel has no recorded base at $sidecar." >&2
            echo "sysinit-llm-capture: run a switch first; without a base there is nothing to compare against." >&2
            return 1
          fi

          local b d
          b="$(mktemp)"; d="$(mktemp)"
          # shellcheck disable=SC2064
          trap "rm -f '$b' '$d'" RETURN
          to_json "$sidecar" "$fmt" > "$b" || return 1
          to_json "$target" "$fmt" > "$d" || return 1

          local changed added n
          changed="$(jq -s -r -f ${changedFile} "$b" "$d")"
          added="$(jq -s -r -f ${addedFile} "$b" "$d")"

          if [ -z "$changed" ] && [ -z "$added" ]; then
            echo "# $name: $rel matches what Nix applied. Nothing to backport."
            return 0
          fi

          echo "# $name: $rel"
          if [ -n "$changed" ]; then
            echo "# Changed from what Nix declares. Paste into the harness config to adopt:"
            printf '%s\n' "$changed"
          fi
          if [ -n "$added" ]; then
            if [ "$show_added" = 1 ]; then
              echo "# Present only in the live file. Usually the harness's own state;"
              echo "# declare a key here only if Nix should own it from now on:"
              printf '%s\n' "$added" | sed 's/^/# /'
            else
              n="$(printf '%s\n' "$added" | grep -c ' = ' || true)"
              echo "# ($n value(s) exist only in the live file. Almost always the"
              echo "#  harness's own runtime state. Pass --all to see them.)"
            fi
          fi
        }

        show_added=0
        if [ "''${1:-}" = "--all" ]; then show_added=1; shift; fi
        if [ "$#" -ne 1 ]; then usage; exit 2; fi
        case "$1" in
          -h | --help) usage; exit 0 ;;
          ${lib.concatStringsSep "\n          " (lib.mapAttrsToList mkCase enabled)}
          *)
            echo "sysinit-llm-capture: no managed file named '$1'." >&2
            usage
            exit 1
            ;;
        esac
      '';
    };

  mkReconciler =
    { pkgs, files }:
    let
      enabled = lib.filterAttrs (_: f: f.enable) files;
      disabled = lib.filterAttrs (_: f: !f.enable) files;

      mergeFile = pkgs.writeText "managed-file-merge3.jq" mergeProgram;

      mkCall =
        name: f:
        let
          newFile =
            if f.contentFile != null then
              f.contentFile
            else
              pkgs.writeText "managed-${name}-new.json" (builtins.toJSON f.content);
        in
        lib.concatStringsSep " " [
          "reconcile"
          (lib.escapeShellArg name)
          (lib.escapeShellArg f.path)
          f.format
          newFile
          (if f.contentFile != null then f.format else "json")
          (if f.schema == null then "-" else f.schema)
          (lib.escapeShellArg (builtins.toJSON (map (e: if builtins.isList e then e else [ e ]) f.enforce)))
          (lib.escapeShellArg (builtins.toJSON (map (e: if builtins.isList e then e else [ e ]) f.retire)))
          (if f.createIfMissing then "create" else "skip")
        ];

      mkForget = _name: f: "forget_base ${lib.escapeShellArg f.path}";
    in
    pkgs.writeShellApplication {
      name = "sysinit-llm-reconcile";
      runtimeInputs = [
        pkgs.jq
        pkgs.yq-go
        pkgs.check-jsonschema
      ];
      text = ''
        ${lib.optionalString (enabled == { })
          "# Every managed file is disabled, so only base cleanup runs and the\n# helpers below are unreachable. Disabling every file is the kill switch;\n# it must still build."
        }
        ${lib.optionalString (enabled == { }) "# shellcheck disable=SC2329\n"}to_json() {
          local raw
          if ! raw="$(
            case "$2" in
              json) jq '.' "$1" ;;
              yaml) yq -p yaml -o json '.' "$1" ;;
              toml) yq -p toml -o json '.' "$1" ;;
            esac
          )"; then
            return 1
          fi
          if [ "$(printf '%s' "$raw" | jq -s 'length')" != "1" ]; then
            return 1
          fi
          if [ "$(printf '%s' "$raw" | jq -r 'type')" != "object" ]; then
            return 1
          fi
          printf '%s\n' "$raw"
        }

        ${lib.optionalString (enabled == { }) "# shellcheck disable=SC2329\n"}from_json() {
          case "$1" in
            json) jq '.' ;;
            yaml) yq -p json -o yaml '... style=""' ;;
            toml) yq -p json -o toml '.' ;;
          esac
        }

        ${lib.optionalString (disabled != { }) ''
          forget_base() {
            local target="$HOME/$1" base_name sidecar
            base_name="$(basename "$target")"
            case "$base_name" in
              .*) sidecar="$(dirname "$target")/$base_name.nix-base" ;;
              *) sidecar="$(dirname "$target")/.$base_name.nix-base" ;;
            esac
            if [ -e "$sidecar" ]; then
              rm -f "$sidecar"
              echo "managed-file: dropped the base for $1 (no longer managed)"
            fi
          }
        ''}

        ${lib.optionalString (enabled == { }) "# shellcheck disable=SC2329\n"}reconcile() {
          local name="$1" rel="$2" fmt="$3" new="$4" new_fmt="$5" schema="$6"
          local enforce="$7" retire="$8" create="$9"
          local target="$HOME/$rel"
          local sidecar base_name
          base_name="$(basename "$target")"
          case "$base_name" in
            .*) sidecar="$(dirname "$target")/$base_name.nix-base" ;;
            *) sidecar="$(dirname "$target")/.$base_name.nix-base" ;;
          esac
          mkdir -p "$(dirname "$target")"

          local tmp result_json
          if ! tmp="$(mktemp "$target.tmp.XXXXXX")" || [ -z "$tmp" ]; then
            echo "managed-file: $name could not create a temp file beside $rel" >&2
            return 1
          fi
          if ! result_json="$(mktemp)" || [ -z "$result_json" ]; then
            rm -f "$tmp"
            echo "managed-file: $name could not create a temp file" >&2
            return 1
          fi
          # shellcheck disable=SC2064
          trap "rm -f '$tmp' '$tmp.disk' '$tmp.disk.s' '$tmp.base' '$tmp.base.s' '$tmp.base.new' '$tmp.new' '$tmp.new.s' '$tmp.merged' '$result_json'" RETURN

          local new_json="$tmp.new"
          if ! to_json "$new" "$new_fmt" > "$new_json"; then
            echo "managed-file: $name cannot parse its own declared content as $new_fmt" >&2
            return 1
          fi

          local is_store_link=0
          if [ -L "$target" ]; then
            case "$(readlink "$target")" in
              /nix/store/*) is_store_link=1 ;;
              *)
                echo "managed-file: $name refuses $rel: it is a symlink to $(readlink "$target"), which this module does not own." >&2
                echo "managed-file: replace it with a regular file if Nix should manage it." >&2
                return 1
                ;;
            esac
          fi

          if [ "$create" = "create" ] && [ -f "$target" ] && [ ! -s "$target" ]; then
            rm -f "$target"
          fi

          if [ "$is_store_link" = 1 ] || [ ! -e "$target" ]; then
            if [ "$create" != "create" ]; then
              if [ "$is_store_link" = 1 ]; then
                echo "managed-file: $name leaves $rel alone: it is a store symlink and createIfMissing is false." >&2
              fi
              return 0
            fi
            if ! cp "$new_json" "$result_json"; then
              echo "managed-file: $name could not stage content for $rel" >&2
              return 1
            fi
            echo "managed-file: $name seeded $rel"
          elif [ ! -f "$target" ]; then
            echo "managed-file: $name refuses $rel: it exists but is not a regular file." >&2
            return 1
          elif [ ! -e "$sidecar" ]; then
            if ! to_json "$target" "$fmt" > "$tmp.disk"; then
              echo "managed-file: $name cannot parse $rel as $fmt" >&2
              return 1
            fi
            if ! jq -S -s --argjson del "$retire" '
                  .[0] as $d | .[1] as $n
                  | ($d | delpaths($del))
                  | (. * $n)
                ' "$tmp.disk" "$new_json" > "$result_json"; then
              echo "managed-file: $name could not adopt $rel" >&2
              return 1
            fi
            echo "managed-file: $name adopted $rel (no base yet)"
          else
            if ! to_json "$sidecar" "$fmt" > "$tmp.base"; then
              echo "managed-file: $name has an unreadable base at $sidecar" >&2
              echo "managed-file: $rel left untouched. Delete the base to re-adopt." >&2
              return 1
            fi
            if ! to_json "$target" "$fmt" > "$tmp.disk"; then
              echo "managed-file: $name cannot parse $rel as $fmt" >&2
              return 1
            fi
            if ! jq --argjson del "$retire" 'delpaths($del)' \
                  "$tmp.disk" > "$tmp.disk.r"; then
              echo "managed-file: $name could not drop the retired keys for $rel" >&2
              return 1
            fi
            mv "$tmp.disk.r" "$tmp.disk"

            if ! jq --argjson paths "$enforce" 'delpaths($paths)' \
                  "$tmp.base" > "$tmp.base.s" \
              || ! jq --argjson paths "$enforce" 'delpaths($paths)' \
                  "$tmp.disk" > "$tmp.disk.s" \
              || ! jq --argjson paths "$enforce" 'delpaths($paths)' \
                  "$new_json" > "$tmp.new.s"; then
              echo "managed-file: $name could not separate the enforced blocks for $rel" >&2
              return 1
            fi
            if ! jq -s -f ${mergeFile} "$tmp.base.s" "$tmp.disk.s" "$tmp.new.s" > "$tmp.merged"; then
              echo "managed-file: $name could not reconcile $rel; it is left untouched" >&2
              return 1
            fi
            if ! jq -S -s --argjson paths "$enforce" '
                  def haspath($p):
                    if ($p | length) == 0 then true
                    elif type != "object" then false
                    elif has($p[0]) then (.[$p[0]] | haspath($p[1:]))
                    else false end;
                  .[0] as $r | .[1] as $n | .[2] as $d
                  | reduce $paths[] as $p ($r;
                      if ($n | haspath($p)) then setpath($p; $n | getpath($p))
                      elif ($d | haspath($p)) then setpath($p; $d | getpath($p))
                      else . end)
                ' "$tmp.merged" "$new_json" "$tmp.disk" > "$result_json"; then
              echo "managed-file: $name could not apply the enforced blocks for $rel" >&2
              return 1
            fi
          fi

          if [ "$schema" != "-" ]; then
            if ! check-jsonschema --schemafile "$schema" "$result_json" > /dev/null 2>&1; then
              echo "managed-file: $name failed schema validation against $schema" >&2
              check-jsonschema --schemafile "$schema" "$result_json" >&2 || true
              return 1
            fi
          fi

          if ! from_json "$fmt" < "$result_json" > "$tmp" || [ ! -s "$tmp" ]; then
            echo "managed-file: $name could not render $rel as $fmt" >&2
            return 1
          fi

          if ! from_json "$fmt" < "$new_json" > "$tmp.base.new" || [ ! -s "$tmp.base.new" ]; then
            echo "managed-file: $name could not render the base for $rel" >&2
            return 1
          fi

          if [ -L "$target" ]; then
            rm -f "$target"
          fi
          if ! mv "$tmp" "$target"; then
            echo "managed-file: $name could not install $rel" >&2
            return 1
          fi
          chmod u+w "$target" || true
          if ! mv "$tmp.base.new" "$sidecar"; then
            echo "managed-file: $name installed $rel but could not write the base at $sidecar" >&2
            echo "managed-file: the next activation re-applies from the older base; no data is lost" >&2
            return 1
          fi
        }

        rc=0
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkForget disabled)}
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (n: f: "${mkCall n f} || rc=1") enabled)}
        exit "$rc"
      '';
    };
in
{
  inherit
    mergeProgram
    formats
    fileDefaults
    mkTestFile
    mkCapture
    mkReconciler
    ;
}
