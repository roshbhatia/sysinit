# Kanata key remapper — maps Super+key → Ctrl+key at the evdev level
# so macOS-like keybindings work natively in every app on NixOS.
# Super alone and Super+non-mapped keys pass through to sway normally.
{ ... }:

{
  # Required for kanata to create virtual input devices
  boot.kernelModules = [ "uinput" ];
  hardware.uinput.enable = true;

  services.kanata = {
    enable = true;
    keyboards.default = {
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        ;; Intercept lmet and pass it through as-is
        ;; defoverrides then remaps Super+letter → Ctrl+letter
        (defsrc lmet)
        (deflayer base lmet)

        (defoverrides
          (lmet c)   (lctl c)         ;; copy
          (lmet v)   (lctl v)         ;; paste
          (lmet x)   (lctl x)         ;; cut
          (lmet a)   (lctl a)         ;; select all
          (lmet z)   (lctl z)         ;; undo
          (lmet lsft z) (lctl lsft z) ;; redo
          (lmet w)   (lctl w)         ;; close tab
          (lmet n)   (lctl n)         ;; new
          (lmet f)   (lctl f)         ;; find
          (lmet t)   (lctl t)         ;; new tab
          (lmet s)   (lctl s)         ;; save
          (lmet r)   (lctl r)         ;; reload
          (lmet l)   (lctl l)         ;; address bar
          (lmet p)   (lctl p)         ;; print
        )
      '';
    };
  };
}
