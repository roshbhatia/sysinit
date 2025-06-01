{
  lib,
  ...
}:

let
  libraryPath = ./library.sh;
in
{
  mkActivationUtils =
    {
      logDir ? "/tmp/sysinit-logs",
      logPrefix ? "sysinit",
      additionalPaths ? [ ],
    }:
    {
      after = [ ];
      before = [ "*" ];
      data = ''
        source ${libraryPath}

        export LOG_DIR="${logDir}"
        export LOG_PREFIX="${logPrefix}"

        ${lib.concatMapStrings (path: ''
          export PATH="${path}:$PATH"
        '') additionalPaths}
      '';
    };

  mkPackageManager =
    {
      name,
      basePackages,
      additionalPackages ? [ ],
      executableArguments,
      executableName,
    }:
    let
      allPackages = basePackages ++ additionalPackages;
      escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
      escapedArguments = lib.concatStringsSep " " (map lib.escapeShellArg executableArguments);
    in
    {
      after = [ "setupActivationUtils" ];
      before = [ ];
      data = ''
        source ${libraryPath}

        log_info "Managing ${name} packages..."

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

  mkActivationScript =
    {
      description ? "",
      script,
      requiredExecutables ? [ ],
      after ? [ "setupActivationUtils" ],
      before ? [ ],
    }:
    {
      inherit after before;
      data = ''
        source ${libraryPath}

        ${if description != "" then ''log_info "Starting: ${description}"'' else ""}

        ${lib.concatMapStrings (exe: ''
          if ! check_executable "${exe}"; then
            log_error "Required executable ${exe} not found"
            exit 1
          fi
        '') requiredExecutables}

        ${script}

        ${if description != "" then ''log_success "${description} completed"'' else ""}
      '';
    };
}
