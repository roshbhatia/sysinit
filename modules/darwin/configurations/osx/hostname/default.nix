{ overlay, ... }:
{
  networking.hostName = overlay.user.hostname;
}
