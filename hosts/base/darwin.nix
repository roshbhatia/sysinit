# Base Darwin (macOS) host configuration
# Inherit this in host-specific configs
{ ... }:

{
  # Base Darwin config is minimal - most configuration comes from
  # modules/darwin which is auto-imported by the builder
  #
  # Host-specific configs should import this and add:
  # - Host-specific homebrew packages
  # - Host-specific stylix theme overrides
  # - Any other host-specific system settings
}
