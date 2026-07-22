{ ... }:

{
  # Prevent lid-close sleep when the Apple Thunderbolt Display is connected.
  # caffeinate -s only blocks sleep on AC power, so this daemon runs as root
  # and calls pmset -a disablesleep 1/0 instead — works on battery too.
  launchd.daemons.clamshell-thunderbolt = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          CONNECTED=""
          is_connected() {
            /usr/sbin/system_profiler SPDisplaysDataType 2>/dev/null \
              | /usr/bin/grep -q "Thunderbolt Display"
          }
          while true; do
            if is_connected; then
              if [ -z "$CONNECTED" ]; then
                /usr/bin/pmset -a disablesleep 1
                CONNECTED=1
              fi
            else
              if [ -n "$CONNECTED" ]; then
                /usr/bin/pmset -a disablesleep 0
                CONNECTED=""
              fi
            fi
            sleep 15
          done
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/clamshell-thunderbolt.log";
      StandardErrorPath = "/var/log/clamshell-thunderbolt.error.log";
    };
  };
}
