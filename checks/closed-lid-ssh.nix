{ pkgs, ... }:

pkgs.runCommand "closed-lid-ssh-test"
  {
    nativeBuildInputs = [ pkgs.bash ];
  }
  ''
    test_root=$TMPDIR/closed-lid-ssh
    mkdir -p "$test_root/bin" "$test_root/state"

    cp ${../modules/darwin/closed-lid-ssh.sh} "$test_root/monitor"
    chmod +x "$test_root/monitor"

    cat > "$test_root/bin/pmset" <<'SCRIPT'
    #!${pkgs.runtimeShell}
    set -eu
    if [ "$1 $2" = "-g batt" ]; then
      reads=0
      if [ -e "$TEST_ROOT/state/reads" ]; then
        reads=$(cat "$TEST_ROOT/state/reads")
      fi
      reads=$((reads + 1))
      printf '%s\n' "$reads" > "$TEST_ROOT/state/reads"
      if [ "$reads" -lt 3 ]; then
        printf "Now drawing from 'AC Power'\n"
      else
        printf "Now drawing from 'Battery Power'\n"
      fi
      exit 0
    fi
    printf '%s\n' "$*" >> "$TEST_ROOT/state/pmset-calls"
    SCRIPT

    cat > "$test_root/bin/logger" <<'SCRIPT'
    #!${pkgs.runtimeShell}
    set -eu
    printf '%s\n' "$*" >> "$TEST_ROOT/state/logger-calls"
    SCRIPT

    cat > "$test_root/bin/sleep" <<'SCRIPT'
    #!${pkgs.runtimeShell}
    set -eu
    sleeps=0
    if [ -e "$TEST_ROOT/state/sleeps" ]; then
      sleeps=$(cat "$TEST_ROOT/state/sleeps")
    fi
    sleeps=$((sleeps + 1))
    printf '%s\n' "$sleeps" > "$TEST_ROOT/state/sleeps"
    if [ "$sleeps" -eq 3 ]; then
      kill -TERM "$PPID"
    fi
    SCRIPT
    chmod +x "$test_root/bin/pmset" "$test_root/bin/logger" "$test_root/bin/sleep"

    export TEST_ROOT="$test_root"
    "$test_root/monitor" \
      "$test_root/bin/pmset" \
      "$test_root/bin/logger" \
      "$test_root/bin/sleep" \
      0 \
      "$test_root/state/enabled"

    cat > "$test_root/expected-pmset" <<'EXPECTED'
    -a disablesleep 1
    -a disablesleep 0
    -a disablesleep 0
    EXPECTED
    diff -u "$test_root/expected-pmset" "$test_root/state/pmset-calls"

    test ! -e "$test_root/state/enabled"
    test "$(grep -c 'disabled on AC power' "$test_root/state/logger-calls")" -eq 1
    test "$(grep -c 'enabled on battery power' "$test_root/state/logger-calls")" -eq 1
    test "$(grep -c 'system sleep enabled$' "$test_root/state/logger-calls")" -eq 1

    touch "$out"
  ''
