{ lib, ... }:

{
  mkLogger = {
    name,
    logDir ? "/tmp/log",
    logPrefix ? "sysinit",
  }: {
    after = [ "fixVariables" ];
    before = [];
    data = ''
      log_info() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
      }
      log_debug() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1"
      }
      log_error() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1"
      }
      log_success() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1"
      }

      LOG_DIR="${logDir}"
      LOG_PREFIX="${logPrefix}"
      mkdir -p "$LOG_DIR"
    '';
  };
}
