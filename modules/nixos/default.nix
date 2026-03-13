{ lib, values, ... }:

{
  imports = [
    ./common
  ]
  ++ lib.optional values.isLima ./lima
  ++ lib.optional values.isDesktop ./desktop;
}
