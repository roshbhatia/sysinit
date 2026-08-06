# `diffnote` writes a note file and neovim renders it. Those are two programs, in
# two languages, that agree only by convention, so this check drives both halves.
#
# What it covers, and why each one is here rather than trusted:
#
#   1. The note path must be byte-identical in `runtime/diffnote.sh` and in
#      `lua/harness/diffnote.lua`. They derive it independently from the same
#      sha256-of-repo-root rule. A drift is silent: the CLI reports success and the
#      editor renders nothing, forever.
#   2. `apply --stdin` must accept hunk's payload shape (`filePath`, `newLine`) as
#      well as this tool's own (`file`, `line`), because the harness skills already
#      emit the former.
#   3. Rejection. A path that escapes the repository with `..`, an absolute path
#      outside it, a non-integral line, a line with a leading zero, a missing
#      summary, and an `oldLine`-only comment must each be refused, and must each
#      leave the store byte-identical. An earlier revision of this check asserted
#      only the absolute-path case, and a critic proved by mutation that the whole
#      `jq` validation block could be deleted with the check still passing.
#   4. A zero-byte store must not become absorbing. That state is what an
#      interrupted first write leaves behind, and testing only `-f` made every
#      later write report success and store nothing, permanently.
#   5. The physical cwd, not the logical one. `rev-parse --show-toplevel` answers
#      physically, so a relative `--file` reached through a symlinked path used to
#      be rejected as outside the repository it was inside. macOS `/tmp` is such a
#      symlink, so this is the ordinary case there, not an exotic one.
#   6. The renderer must place one extmark per anchored ROW, keyed by repo-relative
#      path, clamp a line past the end of the buffer rather than drop the note, cap
#      how many notes one row renders, and clear EVERY buffer it drew into when the
#      view closes. Clearing only the current buffer left notes in the reviewer's
#      real file buffers with nothing but a restart to remove them.
#   7. Control bytes must not survive into either renderer. An escape sequence in a
#      summary could clear the owner's terminal from `diffnote list`, and a `\r`
#      could hide the note's real text.
#
# nvim runs `--clean`, so none of the plugins load and `codediff` is absent. That is
# why `M.draw` is public: the window lookup needs the plugin, the rendering does
# not, and the rendering is the part worth asserting.
{
  pkgs,
  lib,
  ...
}:
let
  runtime = import ../modules/home/programs/llm/runtime { inherit pkgs lib; };
  luaDir = ../modules/home/programs/neovim/config/lua;
in
pkgs.runCommand "diffnote-roundtrip-check"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.git
      pkgs.neovim
    ];
  }
  ''
        export HOME="$TMPDIR/home"
        export XDG_STATE_HOME="$TMPDIR/state"
        mkdir -p "$HOME"

        diffnote=${lib.getExe runtime.diffNote}
        luaDir=${luaDir}
        fail=0
        note() {
          echo "FAIL: $1" >&2
          fail=1
        }

        # Runs nvim --clean with the module on package.path. $1 is the cwd, $2 is lua.
        #
        # stderr goes to a file rather than /dev/null. A Lua error here produces empty
        # stdout, which reads as "the assertion failed" when it actually means "the probe
        # never ran", and those need different fixes.
        nvim_eval() {
          nvim --clean --headless \
            -c "lua package.path = '$luaDir/?.lua;' .. package.path" \
            -c "cd $1" \
            -c "lua $2" \
            -c 'qa!' 2> "$TMPDIR/nvim.err"
          if [ -s "$TMPDIR/nvim.err" ]; then
            echo "  nvim stderr: $(tr '\n' ' ' < "$TMPDIR/nvim.err")" >&2
          fi
        }

        # A real repository: the CLI keys its store on `rev-parse --show-toplevel`.
        repo="$TMPDIR/proj"
        mkdir -p "$repo/src"
        cd "$repo" || exit 1
        git init --quiet -b main
        git config user.email check@example.com
        git config user.name check
        printf 'one\ntwo\nthree\n' > src/app.ts
        printf 'root\n' > README.md
        git add -A
        git commit --quiet -m init

        # --- 1. the two path derivations must agree ------------------------------
        shellPath=$($diffnote path)
        luaPath=$(nvim_eval "$repo" "io.write(require('harness.diffnote')._note_path_for('$repo'))")
        if [ "$shellPath" != "$luaPath" ]; then
          note "note path differs between the CLI and the editor"
          echo "  shell: $shellPath" >&2
          echo "  lua:   $luaPath" >&2
        fi

        # The fallback branch is a separate code path in both halves, and nvim launched
        # from a mux server inherits no session variables, so it is the branch that runs
        # in practice. An earlier revision exported XDG_STATE_HOME for both halves and
        # never exercised it.
        fallbackShell=$(env -u XDG_STATE_HOME "$diffnote" path)
        fallbackLua=$(env -u XDG_STATE_HOME nvim --clean --headless \
          -c "lua package.path = '$luaDir/?.lua;' .. package.path" \
          -c "cd $repo" \
          -c "lua io.write(require('harness.diffnote')._note_path_for('$repo'))" \
          -c 'qa!' 2> /dev/null)
        if [ "$fallbackShell" != "$fallbackLua" ]; then
          note "with XDG_STATE_HOME unset the two halves disagree"
          echo "  shell: $fallbackShell" >&2
          echo "  lua:   $fallbackLua" >&2
        fi
        case $fallbackShell in
          "$HOME"/.local/state/*) ;;
          *) note "the fallback path is not under \$HOME/.local/state: $fallbackShell" ;;
        esac

        # A trailing slash must not change the derived path in EITHER half. Both sides
        # are asserted: the shell strips it explicitly, and the Lua half gets it from
        # `vim.fs.joinpath`, so only one of the two has code that a mutation can kill.
        slashShell=$(XDG_STATE_HOME="$XDG_STATE_HOME/" "$diffnote" path)
        if [ "$slashShell" != "$shellPath" ]; then
          note "a trailing slash on XDG_STATE_HOME changed the CLI's path"
        fi
        slashLua=$(XDG_STATE_HOME="$XDG_STATE_HOME/" nvim --clean --headless \
          -c "lua package.path = '$luaDir/?.lua;' .. package.path" \
          -c "cd $repo" \
          -c "lua io.write(require('harness.diffnote')._note_path_for('$repo'))" \
          -c 'qa!' 2> /dev/null)
        if [ "$slashLua" != "$luaPath" ]; then
          note "a trailing slash on XDG_STATE_HOME changed the editor's path"
        fi

        # --- 2. both payload shapes ----------------------------------------------
        printf '%s\n' '{"comments":[{"filePath":"src/app.ts","newLine":2,"summary":"hunk shape"}]}' \
          | $diffnote apply --stdin > /dev/null
        printf '%s\n' '{"notes":[{"file":"README.md","line":1,"summary":"native shape"}]}' \
          | $diffnote apply --stdin > /dev/null
        count=$($diffnote list --json | jq '.notes | length')
        if [ "$count" != 2 ]; then
          note "expected 2 notes after both payload shapes, got $count"
        fi

        # --- 3. every rejection, and each must leave the store byte-identical ----
        # Named so a failure says which input got through.
        reject_batch() {
          local label=$1 payload=$2 before after
          before=$(jq -cS '.notes' "$shellPath")
          if printf '%s\n' "$payload" | $diffnote apply --stdin > /dev/null 2>&1; then
            note "apply accepted a batch it must reject: $label"
          fi
          after=$(jq -cS '.notes' "$shellPath")
          if [ "$before" != "$after" ]; then
            note "a rejected batch mutated the store ($label); validation must precede the write"
          fi
        }

        reject_batch "path escaping with .." \
          '{"comments":[{"filePath":"../outside.txt","newLine":1,"summary":"escape"}]}'
        reject_batch "absolute path outside the repo" \
          '{"comments":[{"filePath":"/etc/hosts","newLine":1,"summary":"outside"}]}'
        reject_batch "non-integral line" \
          '{"notes":[{"file":"src/app.ts","line":2.5,"summary":"float"}]}'
        reject_batch "line below one" \
          '{"notes":[{"file":"src/app.ts","line":0,"summary":"zero"}]}'
        reject_batch "missing summary" \
          '{"comments":[{"filePath":"src/app.ts","newLine":1}]}'
        reject_batch "oldLine only, which names the original side" \
          '{"comments":[{"filePath":"src/app.ts","oldLine":3,"summary":"removed line"}]}'
        reject_batch "one good item beside one bad one" \
          '{"comments":[{"filePath":"src/app.ts","newLine":1,"summary":"ok"},{"filePath":"../out.txt","newLine":1,"summary":"bad"}]}'

        # `add` must reject the same path and line forms.
        reject_add() {
          local label=$1
          shift
          if $diffnote add "$@" > /dev/null 2>&1; then
            note "add accepted an argument set it must reject: $label"
          fi
        }
        reject_add "path escaping with .." --file ../outside.txt --line 1 --summary x
        reject_add "line with a leading zero" --file src/app.ts --line 00 --summary x
        reject_add "line 0123, which jq would normalize to 123" --file src/app.ts --line 0123 --summary x
        reject_add "the repository root itself" --file . --line 1 --summary x
        # A flag with no value must say so rather than exit silently under errexit.
        if msg=$($diffnote add --file src/app.ts --line 1 --summary 2>&1); then
          note "add accepted --summary with no value"
        elif [ -z "$msg" ]; then
          note "add with a valueless flag exited with no diagnostic at all"
        fi

        # --- 4. a zero-byte store must not become absorbing ----------------------
        cp "$shellPath" "$TMPDIR/store.bak"
        : > "$shellPath"
        $diffnote add --file src/app.ts --line 1 --summary "after truncation" > /dev/null 2>&1 || true
        if [ ! -s "$shellPath" ]; then
          note "a zero-byte store stayed zero bytes after a write; the state is absorbing"
        elif [ "$($diffnote list --json | jq '.notes | length')" -lt 1 ]; then
          note "a write after truncation reported success but stored nothing"
        fi
        # A non-empty store that does not parse must be refused, not overwritten.
        printf 'not json' > "$shellPath"
        if $diffnote add --file src/app.ts --line 1 --summary x > /dev/null 2>&1; then
          note "add overwrote a corrupt store instead of refusing"
        fi
        if [ "$(cat "$shellPath")" != "not json" ]; then
          note "a corrupt store was modified; it must be left for the owner to move aside"
        fi

        # A mid-write producer failure must not publish. This is the case that made the
        # store destroy itself: the write committed whatever arrived, and the producer
        # sits upstream in a pipeline, so its failure was observable only afterwards.
        #
        # `notes: [5]` is the trigger. It satisfies the store's own shape test, so the
        # command proceeds, and then `map(select(.file != $file))` cannot index a
        # number, so jq exits non-zero having emitted nothing.
        scalarStore='{"version":1,"repo":"'"$repo"'","notes":[5]}'
        printf '%s' "$scalarStore" > "$shellPath"
        if $diffnote clear --file src/app.ts > /dev/null 2>&1; then
          note "clear reported success while its jq producer failed"
        fi
        if [ "$(cat "$shellPath")" != "$scalarStore" ]; then
          note "a failed producer replaced the store; write_store must publish only what parses"
          echo "  store is now: $(cat "$shellPath")" >&2
        fi
        cp "$TMPDIR/store.bak" "$shellPath"

        # --- 5. the physical cwd, not the logical one ----------------------------
        # A symlinked route to the same repo is what macOS /tmp is. `cd -P` is not used
        # here on purpose: the shell keeps the logical path, exactly as an agent's cwd
        # would.
        ln -s "$repo" "$TMPDIR/link"
        if ! (cd "$TMPDIR/link" && $diffnote add --file src/app.ts --line 2 --summary "via symlink" > /dev/null 2>&1); then
          note "a relative --file failed when reached through a symlinked path"
        fi

        # --- 6. rendering: one clamped extmark per note, keyed by path -----------
        $diffnote clear --yes > /dev/null
        $diffnote add --file src/app.ts --line 2 --summary "on line two" > /dev/null
        $diffnote add --file src/app.ts --line 99 --summary "past the end" > /dev/null
        $diffnote add --file README.md --line 1 --summary "other file" > /dev/null

        marks=$(nvim_eval "$repo" "
          vim.cmd('edit src/app.ts')
          local d = require('harness.diffnote')
          d.refresh()
          d.draw(0)
          local ns = vim.api.nvim_create_namespace('sysinit_diffnote')
          local rows = {}
          for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})) do
            table.insert(rows, m[2])
          end
          table.sort(rows)
          io.write(#rows .. ':' .. table.concat(rows, ','))
        ")
        # Line 2 is row 1; line 99 clamps to the last row of a 3-line file, row 2. One
        # extmark per row, so two rows means two marks.
        if [ "$marks" != "2:1,2" ]; then
          note "expected 2 extmarks at rows 1 and 2, got '$marks'"
        fi

        # Many notes on one row collapse past the cap, rather than stacking without
        # limit until the code under them is off screen.
        for n in 1 2 3 4 5; do
          $diffnote add --file src/app.ts --line 2 --summary "stacked $n" > /dev/null
        done
        stacked=$(nvim_eval "$repo" "
          vim.cmd('edit src/app.ts')
          local d = require('harness.diffnote')
          d.refresh()
          d.draw(0)
          local ns = vim.api.nvim_create_namespace('sysinit_diffnote')
          local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
          local widest = 0
          for _, m in ipairs(marks) do
            local n = #(m[4].virt_lines or {})
            if n > widest then widest = n end
          end
          io.write(#marks .. ':' .. widest)
        ")
        # Six notes on row 1, capped at 3 rendered plus one "+3 more" line. Each note is
        # one line here (no rationale), so the widest block is 4 lines, not 6.
        if [ "$stacked" != "2:4" ]; then
          note "expected 2 marks with a 4-line capped block, got '$stacked'"
        fi

        other=$(nvim_eval "$repo" "
          vim.cmd('edit README.md')
          local d = require('harness.diffnote')
          d.refresh()
          d.draw(0)
          local ns = vim.api.nvim_create_namespace('sysinit_diffnote')
          io.write(tostring(#vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})))
        ")
        if [ "$other" != 1 ]; then
          note "README.md should carry exactly its own 1 note, got '$other'"
        fi

        # stop() must clear every buffer drawn into, not whichever is current.
        cleared=$(nvim_eval "$repo" "
          local d = require('harness.diffnote')
          local ns = vim.api.nvim_create_namespace('sysinit_diffnote')
          vim.cmd('edit src/app.ts')
          local a = vim.api.nvim_get_current_buf()
          d.refresh()
          d.draw(a)
          vim.cmd('edit README.md')
          local b = vim.api.nvim_get_current_buf()
          d.draw(b)
          -- A third, unrelated buffer is current when the view closes, which is what
          -- happens when the cursor sits in the file explorer.
          vim.cmd('enew')
          d.stop()
          local left = #vim.api.nvim_buf_get_extmarks(a, ns, 0, -1, {})
            + #vim.api.nvim_buf_get_extmarks(b, ns, 0, -1, {})
          io.write(tostring(left))
        ")
        if [ "$cleared" != 0 ]; then
          note "stop() left $cleared extmarks behind in buffers it had drawn into"
        fi

        # --- 7. control bytes must not reach either renderer --------------------
        $diffnote clear --yes > /dev/null
        esc=$(printf 'ok\033[2Jcleared\rhidden')
        $diffnote add --file src/app.ts --line 1 --summary "$esc" > /dev/null
        if $diffnote list | LC_ALL=C grep -q '[[:cntrl:]]'; then
          note "diffnote list emitted a control byte from a note summary"
        fi
        if $diffnote list --json | jq -r '.notes[0].summary' | LC_ALL=C grep -q '[[:cntrl:]]'; then
          note "a control byte survived into the stored summary"
        fi

        # The `file` field is the other sink, and it is the one that cannot be stripped:
        # a path must survive verbatim to match a buffer, so it is rejected instead. An
        # earlier revision routed this case through --summary only, and a note whose PATH
        # carried an escape both reached the terminal and could forge a listing row.
        reject_add "a control byte in the path" --file "$(printf 'src/\033[2Jhax.ts')" --line 1 --summary ok
        reject_add "a newline in the path" --file "$(printf 'src/app.ts\nsrc/other.ts:9  forged')" --line 1 --summary ok
        reject_batch "a control byte in filePath" \
          "$(printf '{"comments":[{"filePath":"src/\\u001b[2Jhax.ts","newLine":1,"summary":"x"}]}')"
        reject_batch "a carriage return in filePath" \
          "$(printf '{"comments":[{"filePath":"src/app.ts\\rsrc/other.ts:9  approved","newLine":1,"summary":"x"}]}')"
        if $diffnote list | LC_ALL=C grep -q '[[:cntrl:]]'; then
          note "diffnote list emitted a control byte from a note path"
        fi

        # A summary of only control bytes must not land as an empty note. `add` validated
        # before sanitizing, so it stored one where `apply` refused the same input.
        reject_add "a summary that is empty once stripped" --file src/app.ts --line 1 --summary "$(printf '\r\a\b')"

        # `apply` must type the fields `add` guarantees, or `list --json` hands a consumer
        # an object where the other entry point promises a string.
        reject_batch "a non-string author" \
          '{"notes":[{"file":"src/app.ts","line":1,"summary":"s","author":{"nested":true}}]}'
        reject_batch "a numeric rationale" \
          '{"notes":[{"file":"src/app.ts","line":1,"summary":"s","rationale":123}]}'

        # --- 8. exit codes, the lock, and the Lua-side filter -------------------
        # `clear` on a repository with no store is success. A bare `return` returned the
        # status of the failed `-s` test, so a documented kill switch reported failure.
        fresh="$TMPDIR/fresh"
        mkdir -p "$fresh"
        (
          cd "$fresh" || exit 1
          git init --quiet -b main
          git config user.email check@example.com
          git config user.name check
          printf 'x\n' > f.txt
          git add -A
          git commit --quiet -m init
          if ! $diffnote clear --yes > /dev/null 2>&1; then
            echo "FAIL: clear --yes on a repository with no store exited non-zero" >&2
            exit 1
          fi
          if ! $diffnote clear --file f.txt > /dev/null 2>&1; then
            echo "FAIL: clear --file on a repository with no store exited non-zero" >&2
            exit 1
          fi
          # `list --json` must carry the same keys on the absent-store path as elsewhere.
          keys=$($diffnote list --json | jq -cS 'keys')
          if [ "$keys" != '["notes","repo","version"]' ]; then
            echo "FAIL: list --json on an absent store returned keys $keys" >&2
            exit 1
          fi
        ) || fail=1

        # A rejected batch must not create a store where none existed. Every earlier
        # rejection ran after the store already existed, so this property was unasserted.
        nostore="$TMPDIR/nostore"
        mkdir -p "$nostore"
        (
          cd "$nostore" || exit 1
          git init --quiet -b main
          git config user.email check@example.com
          git config user.name check
          printf 'x\n' > f.txt
          git add -A
          git commit --quiet -m init
          path=$($diffnote path)
          printf '%s\n' '{"comments":[{"filePath":"../out.txt","newLine":1,"summary":"bad"}]}' \
            | $diffnote apply --stdin > /dev/null 2>&1 || true
          if [ -e "$path" ]; then
            echo "FAIL: a rejected batch created a store at $path" >&2
            exit 1
          fi
        ) || fail=1

        # The lock had no assertion at all: its whole body could be replaced by `"$@"`
        # and every other assertion still passed.
        mkdir "$shellPath.lock"
        if $diffnote add --file src/app.ts --line 1 --summary "should not land" > /dev/null 2>&1; then
          note "add wrote while the store lock was held"
        fi
        rmdir "$shellPath.lock"

        # The editor's own line filter. The CLI cannot produce these, so only a
        # hand-written store exercises it, and design.md D15 treats that as reachable.
        # A malformed note must not take its valid neighbours down with it: a row renders
        # as one extmark, so an unchecked field discarded the whole row.
        $diffnote clear --yes > /dev/null
        cat > "$shellPath" <<JSON
        {"version":1,"repo":"$repo","notes":[
          {"file":"src/app.ts","line":2,"summary":"the valid one","author":"pi"},
          {"file":"src/app.ts","line":2,"author":"pi"},
          {"file":"src/app.ts","line":0,"summary":"line below one","author":"pi"},
          {"file":"src/app.ts","line":2.5,"summary":"non-integral","author":"pi"}
        ]}
    JSON
        survivors=$(nvim_eval "$repo" "
          vim.cmd('edit src/app.ts')
          local d = require('harness.diffnote')
          d.refresh()
          d.draw(0)
          local ns = vim.api.nvim_create_namespace('sysinit_diffnote')
          local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
          local lines = 0
          for _, m in ipairs(marks) do lines = lines + #(m[4].virt_lines or {}) end
          io.write(#marks .. ':' .. lines)
        ")
        # One row, one mark, and exactly the one valid note rendered on it.
        if [ "$survivors" != "1:1" ]; then
          note "expected the one valid note to survive three malformed ones, got '$survivors'"
        fi

        # Attribution is rendered by the editor at the head of the note. Asserted on the
        # chunk text, because a line count cannot see the author chunk disappear.
        $diffnote clear --yes > /dev/null
        $diffnote add --file src/app.ts --line 2 --summary "the summary" --author pi > /dev/null
        head=$(nvim_eval "$repo" "
          vim.cmd('edit src/app.ts')
          local d = require('harness.diffnote')
          d.refresh()
          d.draw(0)
          local ns = vim.api.nvim_create_namespace('sysinit_diffnote')
          local m = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })[1]
          local first = m[4].virt_lines[1]
          -- table.concat, not an accumulator seeded with an empty string literal. The
          -- snippet is passed inside a double-quoted shell argument, where a bare pair
          -- of double quotes is quote-toggling that contributes nothing, leaving the
          -- assignment with no right-hand side. Backticks are avoided here too: this
          -- body is shellchecked, and shellcheck reads them as command substitution.
          local parts = {}
          for _, chunk in ipairs(first) do parts[#parts + 1] = chunk[1] end
          io.write(table.concat(parts))
        ")
        case $head in
          *"pi: the summary"*) ;;
          *) note "the note head must render '<author>: <summary>', got '$head'" ;;
        esac

        # A long rationale must not push the code off screen. The cap bounds rendered
        # LINES as well as note count; a count alone let one note render 400 lines.
        $diffnote clear --yes > /dev/null
        longRationale=$(seq 1 400 | tr '\n' '@' | tr '@' '\n')
        $diffnote add --file src/app.ts --line 2 --summary "long" --rationale "$longRationale" > /dev/null
        longLines=$(nvim_eval "$repo" "
          vim.cmd('edit src/app.ts')
          local d = require('harness.diffnote')
          d.refresh()
          d.draw(0)
          local ns = vim.api.nvim_create_namespace('sysinit_diffnote')
          local m = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })[1]
          io.write(tostring(#m[4].virt_lines))
        ")
        if [ "$longLines" -gt 14 ] 2> /dev/null || [ -z "$longLines" ]; then
          note "one note with a 400-line rationale rendered $longLines virtual lines"
        fi

        # --- notes already on disk must render on start -------------------------
        # `M.start()` set up the fs watcher and never loaded the store, so
        # `state.notes` stayed nil until the file next changed. A note written
        # BEFORE the view opened rendered nothing: reopening a review to reread
        # yesterday's annotations showed an empty diff, and touching the store was
        # the only recovery. The live path hid it, because pi writes after ctrl+b
        # opens the split and the fs event then does the first load. Written
        # before `start()` here, which is exactly the case that broke.
        $diffnote clear --yes > /dev/null
        $diffnote add --file src/app.ts --line 2 --summary "preexisting" --rationale "r" > /dev/null
        preload=$(nvim_eval "$repo" "local d = require('harness.diffnote') d.start() io.write(tostring(d.count()))")
        if [ "$preload" != "1" ]; then
          note "start() did not load an existing note store (count=$preload, expected 1)"
        fi

        [ "$fail" -eq 0 ] || exit 1
        echo "OK: diffnote and the editor agree on the note file, the rejections, the store repair, and the rendering" | tee "$out"
  ''
