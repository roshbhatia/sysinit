# Kanata key remapper — maps Super+key → Ctrl+key at the evdev level
# so macOS-like keybindings work natively in every app on NixOS.
# Super alone and Super+non-letter keys pass through to sway normally.
{ ... }:

{
  services.kanata = {
    enable = true;
    keyboards.default = {
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        ;; Only intercept the Meta (Super) key — everything else passes through
        (defsrc
          lmet
        )

        ;; Base layer: Super key activates the "super" layer while held
        (deflayer base
          (layer-toggle super)
        )

        ;; Super layer: remap letter keys to Ctrl+letter (macOS-like)
        ;; All keys not listed here pass through unchanged via process-unmapped-keys
        (deflayer super
          lmet
        )

        ;; Use defalias + defoverrides for the actual remapping
        ;; defoverrides intercept key combos and remap them
        (defoverrides
          (lmet c)   (lctl c)     ;; Super+C → Ctrl+C (copy)
          (lmet v)   (lctl v)     ;; Super+V → Ctrl+V (paste)
          (lmet x)   (lctl x)     ;; Super+X → Ctrl+X (cut)
          (lmet a)   (lctl a)     ;; Super+A → Ctrl+A (select all)
          (lmet z)   (lctl z)     ;; Super+Z → Ctrl+Z (undo)
          (lmet lsft z) (lctl lsft z) ;; Super+Shift+Z → Ctrl+Shift+Z (redo)
          (lmet w)   (lctl w)     ;; Super+W → Ctrl+W (close tab)
          (lmet n)   (lctl n)     ;; Super+N → Ctrl+N (new)
          (lmet f)   (lctl f)     ;; Super+F → Ctrl+F (find)
          (lmet t)   (lctl t)     ;; Super+T → Ctrl+T (new tab)
          (lmet s)   (lctl s)     ;; Super+S → Ctrl+S (save)
          (lmet r)   (lctl r)     ;; Super+R → Ctrl+R (reload)
          (lmet l)   (lctl l)     ;; Super+L → Ctrl+L (address bar)
          (lmet p)   (lctl p)     ;; Super+P → Ctrl+P (print)
        )
      '';
    };
  };
}
