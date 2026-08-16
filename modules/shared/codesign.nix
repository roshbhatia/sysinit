# macOS keys a TCC grant on the application's designated requirement. A Nix
# build is signed ad hoc, so its requirement is a bare cdhash and every update
# invalidates the grant. Signing with one stable certificate turns the
# requirement into `identifier ... and certificate leaf = H"..."`, which survives
# a rebuild, so a permission granted once stays granted.
#
# A binary that launchd starts straight out of the store has the same problem
# twice over: TCC keys a bare executable on its path, and the store path moves on
# every update. Those are staged into signedBinDir, which does not move.
{
  identity = "sysinit codesign";
  keychainName = "sysinit-codesign.keychain-db";
  signedBinDir = ".local/state/sysinit/signed/bin";
  passwordFile = ".local/state/sysinit/codesign-keychain.pw";
  certFile = ".local/state/sysinit/codesign.crt";
}
