use std/assert

def main [icons: path, plist: path, plugin: path] {
    let root = mktemp -d
    try {
        let source = $root | path join icon.svg
        let manifest = $root | path join sources.json
        let shell = $nu.current-exe
        {icon: $source} | to json | save $manifest
        let valid = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path id="local" d="M0 0h24v24H0z"/><use href="#local"/></svg>'
        for invalid in [
            '<svg viewBox="0 0 24 24"/>'
            '<svg xmlns="http://www.w3.org/2000/svg"/>'
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><g><script/></g></svg>'
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><foreignObject/></svg>'
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><use href="https://example.invalid/image.svg"/></svg>'
        ] {
            $invalid | save --force $source
            let result = ^$shell --no-config-file $icons $manifest | complete
            assert ($result.exit_code != 0)
        }
        $valid | save --force $source
        let passed = ^$shell --no-config-file $icons $manifest | complete
        assert equal $passed.exit_code 0 $passed.stderr
        let png = $root | path join icon.png
        ^rsvg-convert --width 256 --height 256 $source --output $png
        let rendered = ^$shell --no-config-file $icons $manifest $root | complete
        assert equal $rendered.exit_code 0 $rendered.stderr
        ^rsvg-convert --width 128 --height 128 $source --output $png
        let wrong_size = ^$shell --no-config-file $icons $manifest $root | complete
        assert ($wrong_size.exit_code != 0)
        let info = $root | path join Info.plist
        '<plist version="1.0"><dict><key>Retained</key><true/><key>CFBundleName</key><string>Old name</string></dict></plist>' | save $info
        ^$shell --no-config-file --plugins $plugin $plist $info
        let decoded = with-env {NOTIFIER_TEST_PLIST: $info} {
            ^$shell --no-config-file --plugins $plugin --commands 'open --raw $env.NOTIFIER_TEST_PLIST | from plist | to json' | from json
        }
        assert equal $decoded.Retained true
        assert equal $decoded.CFBundleName 'CLI Agents'
        assert equal $decoded.CFBundleIdentifier org.roshbhatia.sysinit.agents
        assert equal $decoded.CFBundleDisplayName 'CLI Agents'
        assert equal $decoded.CFBundleIconFile CLIAgents
    } catch {|failure|
        rm -rf $root
        error make $failure
    }
    rm -rf $root
    print 'notification asset checks passed'
}
