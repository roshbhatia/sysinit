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
  # flake check, for the reason given in config/opencode-render.nix: two
  # hand-copies would agree today and drift on the next edit.
  mergeProgram = ''
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
                else error("conflict at ." + ($q | join(".")) + ": the live file deleted this key and the Nix content changed it") end
              elif ($hb | not) and $hd and $hn then
                if $d[$k] == $n[$k] then .[$k] = $n[$k]
                else error("conflict at ." + ($q | join(".")) + ": the live file and the Nix content each added a different value") end
              elif ($hb | not) and $hd and ($hn | not) then
                .[$k] = $d[$k]
              elif ($hb | not) and ($hd | not) and $hn then
                .[$k] = $n[$k]
              else . end
          )
      else
        error("conflict at ." + ($p | join(".")) + ": the base, the live file, and the Nix content all differ")
      end;

    m3([]; .[0]; .[1]; .[2])
  '';

  formats = [
    "json"
    "yaml"
    "toml"
  ];

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
          (lib.escapeShellArg (builtins.toJSON f.enforce))
          (lib.escapeShellArg (builtins.toJSON f.adoptDelete))
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
        ${lib.optionalString (
          enabled == { }
        ) "# Every managed file is disabled; only base cleanup runs.\n# shellcheck disable=SC2329"}
        # Convert a file in the declared format to JSON on stdout.
        #
        # The merge addresses its inputs positionally, so an input that yields
        # anything other than exactly one JSON object shifts every later
        # operand. A truncated file yields zero values and makes the Nix content
        # read as null; a file with a stray `---` or a second document yields
        # two and makes document two read as the Nix content. Both wipe the
        # file and exit 0. Refuse instead.
        to_json() {
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
        from_json() {
          case "$1" in
            json) jq '.' ;;
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

        reconcile() {
          local name="$1" rel="$2" fmt="$3" new="$4" new_fmt="$5" schema="$6"
          local enforce="$7" adopt_delete="$8" create="$9"
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

          # A leftover home.file symlink is read-only and cannot be merged into,
          # but it is NOT removed here. Everything below can still fail, and an
          # early unlink would leave the harness with no config at all. The
          # unlink happens immediately before the mv, once a validated
          # replacement exists.
          if [ -L "$target" ] || [ ! -f "$target" ]; then
            # A target the harness has never written may be one this repository
            # should not conjure. ~/.claude.json is the case: creating it on a
            # machine where Claude Code has never run fabricates state.
            # `-f`, not `-e`: a resolvable symlink satisfies `-e`, so an `-e`
            # test would skip the guard for exactly the case it protects and
            # replace the pointed-to file with Nix-only content.
            if [ ! -f "$target" ] && [ "$create" != "create" ]; then
              return 0
            fi
            if ! cp "$new_json" "$result_json"; then
              echo "managed-file: $name could not stage content for $rel" >&2
              return 1
            fi
            echo "managed-file: $name seeded $rel"
          elif [ ! -e "$sidecar" ]; then
            # First activation after conversion. Adopt once: deep-merge the new
            # content over the live file with Nix winning, exactly what the old
            # two-way scripts did, then seed the base so every later run gets
            # the three-way merge.
            if ! to_json "$target" "$fmt" > "$tmp.disk"; then
              echo "managed-file: $name cannot parse $rel as $fmt" >&2
              return 1
            fi
            # `adoptDelete` names keys this repository used to declare and has
            # retired. A deep merge preserves them, and a schema with
            # `additionalProperties: false` then rejects the result.
            # -S matches the key order the three-way merge emits (it builds
            # objects from a `unique` key set, which sorts). Without it the
            # first three-way run rewrites the whole file for ordering alone.
            if ! jq -S -s --argjson del "$adopt_delete" '
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
            if ! jq --argjson keys "$enforce" 'reduce $keys[] as $k (.; del(.[$k]))' \
                  "$tmp.base" > "$tmp.base.s" \
              || ! jq --argjson keys "$enforce" 'reduce $keys[] as $k (.; del(.[$k]))' \
                  "$tmp.disk" > "$tmp.disk.s" \
              || ! jq --argjson keys "$enforce" 'reduce $keys[] as $k (.; del(.[$k]))' \
                  "$new_json" > "$tmp.new.s"; then
              echo "managed-file: $name could not separate the enforced blocks for $rel" >&2
              return 1
            fi
            if ! jq -s -f ${mergeFile} "$tmp.base.s" "$tmp.disk.s" "$tmp.new.s" > "$tmp.merged"; then
              echo "managed-file: $name could not reconcile $rel; it is left untouched" >&2
              return 1
            fi
            # Re-add the enforced blocks from the Nix content. A block Nix does
            # not declare keeps whatever the live file holds, matching the old
            # `authoritative` pass, which only ever overwrote a declared block.
            if ! jq -S -s --argjson keys "$enforce" '
                  .[0] as $r | .[1] as $n
                  | reduce $keys[] as $k ($r; if ($n | has($k)) then .[$k] = $n[$k] else . end)
                ' "$tmp.merged" "$new_json" > "$result_json"; then
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
    mkReconciler
    ;
}
