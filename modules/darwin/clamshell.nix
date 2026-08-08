{
  # Prevent lid-close sleep when the Apple Thunderbolt Display is connected.
  # system_profiler reports it as "Thunderbolt Display"; caffeinate -s holds
  # a system-sleep assertion that is only active on AC power.
  launchd.user.agents.clamshell-thunderbolt = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          CAFPID=""
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
