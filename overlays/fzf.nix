_final: prev: {
  fzf = prev.fzf.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # Backport #4934 until an fzf release supports Nushell 0.116 completion.
      (prev.fetchpatch {
        url = "https://github.com/junegunn/fzf/commit/55c122f1a0e1340546c8709682bea5561fe0e8fd.patch";
        includes = [ "shell/completion.nu" ];
        hash = "sha256-yDiRFrmBTjWXs+IAq0rd9A++IuKAa7LV+03tWACCZFg=";
      })
    ];
  });
}
