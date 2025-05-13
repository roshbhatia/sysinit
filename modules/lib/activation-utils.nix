{ lib, ... }:

let
  # Define the path to the activation tools shell script
  activationToolsPath = ./activation-tools.sh;
in {
  /**
   * Creates an activation utils script for PATH management and logging functions
   * 
   * This function must be called early in the activation setup to ensure PATH and logging 
   * are available for all subsequent activations.
   */
  mkActivationUtils = {
    logDir ? "/tmp/sysinit-logs",
    logPrefix ? "sysinit",
    additionalPaths ? [],
  }: {
    # Ensure this runs first, before other activation scripts
    after = [];
    before = [ "*" ];
    data = ''
      # Source the activation tools
      source ${activationToolsPath}
      
      # Set custom log directory and prefix if provided
      export LOG_DIR="${logDir}"
      export LOG_PREFIX="${logPrefix}"
      
      # Add additional paths if specified
      ${lib.concatMapStrings (path: ''
        export PATH="${path}:$PATH"
      '') additionalPaths}
      
      log_debug "Activation utilities initialized with custom settings"
    '';
  };
  
  /**
   * Creates a package manager activation script
   * 
   * Requires the activation utils to be set up first
   */
  mkPackageManager = {
    name,
    basePackages,
    additionalPackages ? [],
    executableArguments,
    executableName,
  }: let
    allPackages = basePackages ++ additionalPackages;
    escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
    escapedArguments = lib.concatStringsSep " " (map lib.escapeShellArg executableArguments);
  in {
    # Make sure this runs after the activation utils
    after = [ "setupActivationUtils" ];
    before = [];
    data = ''
      # Source the activation tools
      source ${activationToolsPath}
      
      log_info "Managing ${name} packages..."
      
      # Check if executable exists
      if check_executable "${executableName}"; then
        EXECUTABLE="${executableName}"
        PACKAGES='${escapedPackages}'
        
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            log_command "$EXECUTABLE ${escapedArguments} $package" "Installing $package via ${name}"
          done
          log_success "All ${name} packages processed"
        else
          log_info "No ${name} packages specified"
        fi
      else
        log_error "${name} not found at ${executableName}"
        exit 1
      fi
    '';
  };
  
  /**
   * Creates a custom activation script that uses the activation utils
   */
  mkActivationScript = {
    description ? "",
    script,
    requiredExecutables ? [],
    after ? [ "setupActivationUtils" ],
    before ? [],
  }: {
    inherit after before;
    data = ''
      # Source the activation tools
      source ${activationToolsPath}
      
      ${if description != "" then ''log_info "Starting: ${description}"'' else ""}
      
      # Check required executables
      ${lib.concatMapStrings (exe: ''
        if ! check_executable "${exe}"; then
          log_error "Required executable ${exe} not found"
          exit 1
        fi
      '') requiredExecutables}
      
      # Run the script
      ${script}
      
      ${if description != "" then ''log_success "${description} completed"'' else ""}
    '';
  };
}
