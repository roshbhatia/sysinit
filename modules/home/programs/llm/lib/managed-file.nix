# Reconciles a config file that both Nix and a harness write.
#
# Nix records the content it applied as a sidecar base next to the target, so
# the next activation gets a real three-way merge of base, live file, and new
# content. The base is what lets an undeclared key be deleted: a two-way deep
# merge preserves whatever is on disk, which is why the harness configs used to
# need hand-written `retired` tombstone lists.
#
# Ownership is derived, not declared. A key changed only by Nix takes the Nix
# value, a key changed only by the harness keeps the harness value, and a key
# changed by both to different values fails activation rather than silently
# discarding one side.
{ lib }:
let
  # One jq program, rendered once and shared by the activation script and the
  # flake check, for the reason given in harnesses/opencode/render.nix: two
  # hand-copies would agree today and drift on the next edit.
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
                # Nix undeclared the key. Delete it only if the harness left it
                # alone; an edited value is the owner's, so undeclaring is not
                # licence to discard it.
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

  # The option defaults, in one place so a check can build a reconciler without
  # going through the module system. Keep in sync with options.nix; the
  # `managed-file-reconcile` check fails loudly if a required field is missing.
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

  # Renders JSON as a Nix attrset. The point of `capture` is to hand back
  # something pasteable into the harness config, so it emits Nix rather than a
  # diff the owner has to translate.
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

  # Reports what the owner changed from inside a harness, as Nix source.
  # `diff(base, live)` is exactly that set: the base records what Nix applied,
  # so anything the live file says differently came from the harness or the
  # owner. Prints to stdout and never writes under modules/.
  mkCapture =
    { pkgs, files }:
    let
      enabled = lib.filterAttrs (_: f: f.enable) files;
      # `jq -f` reads the whole program from the file, so the helper defs and
      # the query have to ship as one file rather than as -f plus a positional.
      #
      # Both walks recurse. A whole-block comparison is useless here: goose
      # fills description/display_name/available_tools into every extension at
      # runtime, so the entire `extensions` block reads as changed and buries
      # the one key the owner actually touched.
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

          # Changed: Nix declares it and the live file disagrees. These are the
          # backport candidates. Added: the live file has a key Nix never
          # declared, which is usually the harness's own state, so it is
          # reported separately rather than mixed in.
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

      # Nix always renders JSON, whatever the target format. The script converts
      # on the way out, so one merge path serves all three formats.
      #
      # `contentFile` takes an already-rendered file instead of an attrset, for
      # a target whose content another Home Manager module assembles. Codex is
      # the case: `programs.codex` folds settings, profiles, and transformed MCP
      # servers into one TOML, and duplicating that assembly here would drift
      # from the module on the next upgrade.
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
          # A bare string is one literal key, a list is a path. Not dot-splitting
          # a string is the whole point: amp's settings use VS Code-style keys, so
          # `"amp.permissions"` is ONE key whose name contains dots, and splitting
          # it would enforce a nested path that does not exist while the real key
          # quietly fell back to merging. Normalise to jq's path shape here so the
          # script has one representation to handle.
          (lib.escapeShellArg (builtins.toJSON (map (e: if builtins.isList e then e else [ e ]) f.enforce)))
          (lib.escapeShellArg (builtins.toJSON f.retire))
          (if f.createIfMissing then "create" else "skip")
        ];

      # A disabled target keeps whatever it holds, but its base must go. A base
      # left behind is a record of an activation that no longer happens, and
      # re-enabling later would merge against it and report the owner's own
      # edits as conflicts.
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
        # Convert a file in the declared format to JSON on stdout.
        #
        # The merge addresses its inputs positionally, so an input that yields
        # anything other than exactly one JSON object shifts every later
        # operand. A truncated file yields zero values and makes the Nix content
        # read as null; a file with a stray `---` or a second document yields
        # two and makes document two read as the Nix content. Both wipe the
        # file and exit 0. Refuse instead.
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

        # Convert JSON on stdin back to the declared format on stdout.
        # `... style=""` is not cosmetic: yq carries each node's flow style over
        # from its input, and the input here is JSON, so without the reset a
        # YAML target is rewritten as one unreadable single-line blob that then
        # seeds the next merge.
        ${lib.optionalString (enabled == { }) "# shellcheck disable=SC2329\n"}from_json() {
          case "$1" in
            json) jq '.' ;;
            # `... style=""` is a no-op on a JSON input, which carries no node
            # style; it is kept so the transform stays block-style if this path ever
            # reads YAML. Verified against yq v4.53.3.
            yaml) yq -p json -o yaml '... style=""' ;;
            toml) yq -p json -o toml '.' ;;
          esac
        }

        ${lib.optionalString (disabled != { }) ''
          # Drop the base for a target this configuration no longer reconciles.
          # A base left behind records an activation that no longer happens, so
          # re-enabling later would merge against it and report the owner's own
          # edits as conflicts.
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
          # Hidden so a harness that globs its own config directory does not
          # read it as a second config. An already-hidden target keeps one dot,
          # so ~/.claude.json pairs with ~/.claude.json.nix-base rather than
          # ~/..claude.json.nix-base.
          local sidecar base_name
          base_name="$(basename "$target")"
          case "$base_name" in
            .*) sidecar="$(dirname "$target")/$base_name.nix-base" ;;
            *) sidecar="$(dirname "$target")/.$base_name.nix-base" ;;
          esac
          mkdir -p "$(dirname "$target")"

          # Every command below is checked explicitly. `set -e` does not apply
          # here: reconcile is invoked in a `|| rc=1` context, which disables it
          # for the whole call.
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
          # Set only once both names are known non-empty. An empty $tmp would
          # expand the cleanup to a bare `.disk` and `.base`, resolved against
          # the caller's working directory rather than the target directory.
          # shellcheck disable=SC2064
          trap "rm -f '$tmp' '$tmp.disk' '$tmp.disk.s' '$tmp.base' '$tmp.base.s' '$tmp.base.new' '$tmp.new' '$tmp.new.s' '$tmp.merged' '$result_json'" RETURN

          # `new` may itself be a rendered TOML/YAML file rather than JSON.
          local new_json="$tmp.new"
          if ! to_json "$new" "$new_fmt" > "$new_json"; then
            echo "managed-file: $name cannot parse its own declared content as $new_fmt" >&2
            return 1
          fi

          # A symlink is two cases needing opposite handling, and neither `-e`
          # nor `-f` separates them, because both follow the link. A link into
          # the store is a leftover home.file entry holding nothing but Nix
          # content, so replacing it loses nothing. A link anywhere else is the
          # owner's, and what it points at is real data.
          #
          # The unlink happens immediately before the mv, not here: everything
          # below can still fail, and an early unlink would leave the harness
          # with no config at all.
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

          # A zero-byte target is semantically absent, not corrupt. Treating it
          # as a parse failure would report an error on every activation and
          # never manage the file. Gated on `create`: on the skip path this
          # would be an unconditional delete of harness state by a module that
          # has just declared it must not create that state, and a crashed
          # harness is exactly what produces a zero-byte file.
          if [ "$create" = "create" ] && [ -f "$target" ] && [ ! -s "$target" ]; then
            rm -f "$target"
          fi

          if [ "$is_store_link" = 1 ] || [ ! -e "$target" ]; then
            # A target the harness has never written may be one this repository
            # should not conjure. ~/.claude.json is the case: creating it on a
            # machine where Claude Code has never run fabricates state. Seeding
            # writes Nix-only content, which is precisely what is refused here,
            # so this returns for a store symlink as well as for an absent
            # target. linkGeneration cleans a stale link up on its own.
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
            # First activation after conversion. Adopt once: deep-merge the new
            # content over the live file with Nix winning, exactly what the old
            # two-way scripts did, then seed the base so every later run gets
            # the three-way merge.
            if ! to_json "$target" "$fmt" > "$tmp.disk"; then
              echo "managed-file: $name cannot parse $rel as $fmt" >&2
              return 1
            fi
            # `retire` names keys this repository used to declare, or that the
            # harness writes and nothing reads. A deep merge preserves them, and a
            # schema with `additionalProperties: false` then rejects the result.
            # -S matches the key order the three-way merge emits (it builds
            # objects from a `unique` key set, which sorts). Without it the
            # first three-way run rewrites the whole file for ordering alone.
            if ! jq -S -s --argjson del "$retire" '
                  .[0] as $d | .[1] as $n
                  | (reduce $del[] as $k ($d; del(.[$k])))
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
            # Enforced blocks are removed from all three inputs BEFORE the
            # merge, not patched onto the result afterwards. The merge aborts
            # the whole file on a three-way divergence, so leaving an enforced
            # key in would let a harness edit to it block every other key from
            # updating, which is the exact outcome `enforce` exists to prevent.
            # Retired keys leave the disk BEFORE the merge sees it. A key that was
            # never declared is absent from the base, and the merge preserves
            # base-absent + disk-present on purpose, so nothing else can remove it.
            if ! jq --argjson del "$retire" 'reduce $del[] as $k (.; del(.[$k]))' \
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
            # Re-add the enforced blocks. Nix wins where it declares the block.
            # Where it does not, the live value comes back rather than being
            # dropped, matching the old `authoritative` pass, which only ever
            # overwrote a block the managed content actually carried. The
            # The third input is the UNSTRIPPED disk. The stripped copy has
            # every enforced key deleted, so `has($k)` on it is never true and
            # the fallback would be a silent no-op.
            # `getpath` cannot answer presence: it returns null for an absent key
            # and for a key whose value IS null, and the two mean opposite things
            # here. Absent must fall through to the next source; an explicit null
            # is a value Nix declared and must be restored.
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

          # Known limitation, deliberately not warned about. A target truncated
          # to a valid prefix (YAML and TOML are line oriented) is byte-for-byte
          # indistinguishable from the owner deliberately deleting those keys,
          # and the merge honours deletion on purpose. A warning here fires on
          # every deliberate deletion, repeats on every activation with no way
          # to acknowledge it, and the only remedy it could name -- delete the
          # base and re-adopt -- is exactly the action that reverts the owner's
          # edit. An inaccurate warning that recommends data loss is worse than
          # none.
          #
          # The residual exposure is real and not fully covered. `enforce` does
          # restore a key that must survive a partial write, but few targets
          # declare one, so a truncated codex TOML is still lost silently.
          # Enforcing a whole block was tried and reverted: goose fills in
          # description/display_name/available_tools at runtime, so enforcing
          # `extensions` strips them on every activation and goose writes them
          # back. That is why `enforce` takes a path rather than a top-level key.
          # A path reaches the one entry whose value is load-bearing and leaves
          # its siblings to the merge, which is a narrower instrument than the
          # block-level enforcement that was rejected. It is still not a general
          # answer to truncation: closing that needs a signal the merge does not
          # have, not more enforced paths.
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

          # The base records what Nix applied, never the merged result. Merging
          # the result in would fold the harness's own keys into the base, and
          # the next run could no longer tell who owned them.
          #
          # Rendered before the target is touched, so a failure here costs
          # nothing, but INSTALLED after it. Order matters and only one order
          # is recoverable. A base newer than the target is permanent: the
          # merge short-circuits on `new == base` and returns the stale disk
          # forever. A base older than the target self-corrects on the next
          # run, because disk then equals the new content and the merge takes
          # it.
          if ! from_json "$fmt" < "$new_json" > "$tmp.base.new" || [ ! -s "$tmp.base.new" ]; then
            echo "managed-file: $name could not render the base for $rel" >&2
            return 1
          fi

          # Only now is the old file expendable: a validated replacement exists.
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
