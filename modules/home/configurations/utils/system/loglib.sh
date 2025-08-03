#!/usr/bin/env bash
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/home/configurations/utils/loglib.sh

log_info()
           {
  echo -e "\033[0;34m[INFO]\033[0m $*"
}

log_warn()
           {
  echo -e "\033[1;33m[WARN]\033[0m $*" >&2
}

log_error()
            {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
}

log_success()
              {
  echo -e "\033[0;32m[SUCCESS]\033[0m $*"
}
