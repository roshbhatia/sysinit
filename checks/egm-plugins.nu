use std/assert

def main [output: path] {
    let settings = open ($output | path join config.toml)
    assert $settings.plugins."egm@egm".enabled
    let marketplace = $settings.marketplaces.egm
    assert equal $marketplace.source_type local
    assert equal ($marketplace.source | path expand --strict) ($output | path join bundle | path expand --strict)
    let skills = [
        egm-bootstrap
        egm-brainstorm
        egm-draft
        egm-drift-report
        egm-resolve
        egm-review
        egm-review-loop
    ]
    for root in [
        ($output | path join bundle)
        ($output | path join claude)
    ] {
        for name in $skills {
            assert equal ($root | path join skills $name SKILL.md | path type) file $name
        }
        for relative in [agents resources/document_standards docs/codex.md] {
            assert ($root | path join $relative | path exists) $relative
        }
    }
    let claude = $output | path join claude | path expand --strict
    let manifest = open ($claude | path join .claude-plugin plugin.json)
    let parts = $claude | path split
    for agent in $manifest.agents {
        let resolved = $claude | path join $agent | path expand --strict | path split
        assert equal ($resolved | take ($parts | length)) $parts $agent
    }
    print 'Pinned EGM marketplace, complete bundles, and native enablement verified'
}
