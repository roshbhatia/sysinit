{
  lib,
  ...
}:

with lib;

{
  /*
    Platform-specific path utilities.

    Provides normalized access to platform-dependent paths to ensure
    portability across macOS, Linux, and other platforms.
  */

  /*
    Get the home directory path for a user.

    Arguments:
      username: string - Username
      system: string - System type (aarch64-darwin, x86_64-linux, etc.)

    Returns:
      string - Absolute home directory path
  */
  getUserHome =
    username: system:
    if hasPrefix "darwin" system then
      "/Users/${username}"
    else if hasPrefix "linux" system then
      "/home/${username}"
    else
      throw "Unsupported system: ${system}. Expected darwin or linux-based system";

  /*
    Determine if a system is macOS.

    Arguments:
      system: string - System type

    Returns:
      bool - True if macOS/darwin
  */
  isDarwin = system: hasPrefix "darwin" system;

  /*
    Determine if a system is Linux.

    Arguments:
      system: string - System type

    Returns:
      bool - True if linux
  */
  isLinux = system: hasPrefix "linux" system;

  /*
    Get the applications directory path.

    Arguments:
      system: string - System type

    Returns:
      string - Absolute applications directory path
  */
  getAppsDirectory =
    system:
    if isDarwin system then
      "/Applications"
    else if isLinux system then
      "/usr/local/bin"
    else
      throw "Unsupported system: ${system}";

  /*
    Get the system library paths.

    Arguments:
      system: string - System type

    Returns:
      list - System library paths for the platform
  */
  getSystemLibraryPaths =
    system:
    if isDarwin system then
      [
        "/Library"
        "/System/Library"
      ]
    else if isLinux system then
      [
        "/usr/lib"
        "/usr/lib64"
      ]
    else
      throw "Unsupported system: ${system}";

  /*
    Get daemon configuration directory.

    Arguments:
      system: string - System type

    Returns:
      string - Path to daemon configuration directory
  */
  getDaemonConfigDir =
    system:
    if isDarwin system then
      "/Library/LaunchDaemons"
    else if isLinux system then
      "/etc/systemd/system"
    else
      throw "Unsupported system: ${system}";

  /*
    Get configuration directory name for a service.

    Arguments:
      system: string - System type
      serviceName: string - Service/daemon name

    Returns:
      string - Full path to service configuration
  */
  getServiceConfigPath =
    system: serviceName:
    let
      daemonDir = getDaemonConfigDir system;
    in
    if isDarwin system then
      "${daemonDir}/${serviceName}.plist"
    else if isLinux system then
      "${daemonDir}/${serviceName}.service"
    else
      throw "Unsupported system: ${system}";

  /*
    Validate a path is appropriate for the target system.

    Arguments:
      path: string - Path to validate
      system: string - Target system type

    Returns:
      bool - True if path is valid for system
  */
  isValidPathForSystem =
    path: system:
    let
      isDarwinPath =
        hasPrefix "/Users/" path
        || hasPrefix "/Applications" path
        || hasPrefix "/Library" path
        || hasPrefix "/System/Library" path;
      isLinuxPath =
        hasPrefix "/home/" path
        || hasPrefix "/usr/" path
        || hasPrefix "/opt/" path
        || hasPrefix "/etc/" path;
      isUniversalPath =
        hasPrefix "~" path || hasPrefix "$" path || hasPrefix "/tmp" path || hasPrefix "/var" path;
    in
    if isDarwin system then
      isDarwinPath || isUniversalPath
    else if isLinux system then
      isLinuxPath || isUniversalPath
    else
      false;

  /*
    Validate all paths in configuration are valid for the target system.

    Arguments:
      config: attrs - Configuration with path references
      system: string - Target system type
      pathKeys: list - Keys to check for paths

    Returns:
      bool - True if all paths are valid
  */
  validatePathsForSystem =
    config: system: pathKeys:
    let
      invalidPaths = filter (
        key: hasAttr key config && !isValidPathForSystem config.${key} system
      ) pathKeys;
    in
    if length invalidPaths > 0 then
      throw "Paths invalid for system ${system}: ${concatStringsSep ", " invalidPaths}"
    else
      true;

  /*
    Extract architecture from system type.

    Arguments:
      system: string - Full system type (e.g., aarch64-darwin, x86_64-linux)

    Returns:
      string - Architecture component (aarch64, x86_64, arm64, etc.)
  */
  getArchitecture =
    system:
    let
      parts = builtins.split "-" system;
    in
    if length parts > 0 then elemAt parts 0 else system;

  /*
    Determine CPU architecture name for Homebrew.

    Homebrew uses different architecture names on different systems.

    Arguments:
      system: string - System type

    Returns:
      string - Homebrew-style architecture name
  */
  getBrewArchitecture =
    system:
    let
      arch = getArchitecture system;
    in
    if arch == "aarch64" then
      "arm64"
    else if arch == "x86_64" then
      "x86_64"
    else
      arch;

  /*
    Get Homebrew installation prefix for the system.

    Arguments:
      system: string - System type

    Returns:
      string - Homebrew prefix path
  */
  getBrewPrefix =
    system:
    if isDarwin system then
      let
        arch = getBrewArchitecture system;
      in
      if arch == "arm64" then "/opt/homebrew" else "/usr/local"
    else
      "/usr/local";

  /*
    Get Homebrew binary directory for the system.

    Arguments:
      system: string - System type

    Returns:
      string - Path to Homebrew bin directory
  */
  getBrewBinDir = system: "${getBrewPrefix system}/bin";

  /*
    Is this an x86_64 system?

    Arguments:
      system: string - System type

    Returns:
      bool - True if x86_64 architecture
  */
  isX86_64 = system: getArchitecture system == "x86_64";

  /*
    Is this an ARM-based system (aarch64)?

    Arguments:
      system: string - System type

    Returns:
      bool - True if ARM/aarch64 architecture
  */
  isARM = system: getArchitecture system == "aarch64";
}
