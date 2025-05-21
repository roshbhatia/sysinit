#!/bin/bash

# Define log levels
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1"
}

# Start of script
log_info "Script execution started."

# Simulate some tasks
log_info "Checking if /tmp directory is writable."
if [ -w /tmp ]; then
    log_info "/tmp directory is writable."
else
    log_warn "/tmp directory is not writable."
fi

log_info "Creating a test file in /tmp."
touch /tmp/testfile
if [ $? -eq 0 ]; then
    log_info "Test file creation succeeded."
else
    log_error "Failed to create test file in /tmp."
fi

# Simulate a loop with logging
log_info "Starting loop for simulated task..."
for i in {1..5}; do
    log_info "Loop iteration $i: Performing some work..."
    sleep 1
    if [ $((i % 2)) -eq 0 ]; then
        log_warn "Loop iteration $i: Simulated warning."
    fi
done

log_info "Loop completed."

# Simulate an error case
log_info "Trying to read a non-existent file."
if cat /tmp/nonexistentfile &>/dev/null; then
    log_info "Successfully read the non-existent file."
else
    log_error "Failed to read non-existent file."
fi

# End of script
log_info "Script execution completed."

