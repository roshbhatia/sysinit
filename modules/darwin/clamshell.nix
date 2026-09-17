{ config, lib, ... }:
{
  launchd.user.agents.clamshell-thunderbolt = lib.mkIf (!config.sysinit.darwin.closedLidSsh.enable) {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          CAFPID=""
          cleanup() {
            if [ -n "$CAFPID" ]; then
              kill "$CAFPID" 2>/dev/null || true
              wait "$CAFPID" 2>/dev/null || true
            fi
          }
          trap cleanup EXIT
          trap 'exit 0' HUP INT TERM
          is_connected() {
            /usr/sbin/system_profiler SPDisplaysDataType 2>/dev/null \
              | /usr/bin/grep -q "Thunderbolt Display"
          }
          while true; do
            if is_connected; then
              if [ -z "$CAFPID" ]; then
                /usr/bin/caffeinate -s &
                CAFPID=$!
              fi
            else
              if [ -n "$CAFPID" ]; then
                kill "$CAFPID" 2>/dev/null
                CAFPID=""
              fi
            fi
            sleep 15
          done
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/clamshell-thunderbolt.log";
      StandardErrorPath = "/tmp/clamshell-thunderbolt.error.log";
    };
  };
}
