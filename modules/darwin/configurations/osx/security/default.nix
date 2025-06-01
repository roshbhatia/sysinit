{username, ...}: {
  security.pam.services.sudo_local.touchIdAuth = true;
  system.defaults.alf = {
    allowdownloadsignedenabled = 1;
    globalstate = 0;
  };
}
