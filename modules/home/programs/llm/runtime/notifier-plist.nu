def main [path: path] {
    let info = open --raw $path | from plist

    $info | merge {
        CFBundleIdentifier: org.roshbhatia.sysinit.agents
        CFBundleName: 'CLI Agents'
        CFBundleDisplayName: 'CLI Agents'
        CFBundleIconFile: CLIAgents
    } | to plist | save --force $path
}
