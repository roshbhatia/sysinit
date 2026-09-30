{
  identity = "sysinit codesign";
  keychainName = "sysinit-codesign.keychain-db";
  signedBinDir = ".local/state/sysinit/signed/bin";
  passwordFile = ".local/state/sysinit/codesign-keychain.pw";
  certFile = ".local/state/sysinit/codesign.crt";
}
