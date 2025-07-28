# Nushell config test suite
use std/assert

# Test: Banner is suppressed
def test_banner [] {
  let config = (nu --login -c 'echo $env.config.show_banner' | str trim)
  assert ($config == 'false') 'Banner is not suppressed!'
}

# Test: macchina runs and outputs version
def test_macchina [] {
  let out = (macchina --version | str trim)
  assert ($out | str contains 'macchina') 'macchina not found or not working!'
}

# Test: oh-my-posh prompt is loaded (checks for OMP config file)
def test_oh_my_posh [] {
  let exists = (ls ~/.cache/omp.nu | length) > 0
  assert $exists 'oh-my-posh prompt config not found!'
}

# Test: Entrypoint scripts exist and are callable
def test_entrypoints [] {
  let scripts = [
    'dns-flush.nu'
    'fzf-preview.nu'
    'gh-whoami.nu'
    'git-ai-commit.nu'
  ]
  for s in $scripts {
    let path = ($nu.default-config-dir | path join 'scripts' | path join $s)
    assert (ls $path | length) > 0 $"Entrypoint script ($s) missing!"
  }
}

# Test: Environment variables set
def test_env_vars [] {
  let vars = [
    'LANG'
    'LC_ALL'
    'XDG_CACHE_HOME'
    'XDG_CONFIG_HOME'
    'XDG_DATA_HOME'
    'XDG_STATE_HOME'
    'SUDO_EDITOR'
    'VISUAL'
    'GIT_DISCOVERY_ACROSS_FILESYSTEM'
  ]
  for v in $vars {
    assert ($env | get $v | is-empty | not) $"Env var ($v) not set!"
  }
}

# Run all tests
test_banner
print '✓ Banner suppression test passed'
test_macchina
print '✓ Macchina test passed'
test_oh_my_posh
print '✓ oh-my-posh prompt test passed'
test_entrypoints
print '✓ Entrypoint scripts test passed'
test_env_vars
print '✓ Environment variables test passed'

print 'All Nushell config tests passed!'
