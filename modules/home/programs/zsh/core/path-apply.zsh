#!/usr/bin/env zsh
# shellcheck disable=all
# Apply the configured path list. default.nix sets SYSINIT_PATHS immediately
# before this runs; that assignment is the only Nix-generated shell left in the
# module.
#
# This used to be a generated `path.add.bulk \` line-continuation chain built by
# concatStringsSep in default.nix. A continuation chain assembled from
# interpolated values is exactly the shape a parse check cannot see, so the loop
# moved here and only the array literal stays generated.

path.add.bulk "${SYSINIT_PATHS[@]}"
unset SYSINIT_PATHS
