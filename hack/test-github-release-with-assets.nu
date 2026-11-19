use std/assert
use ./github-release-with-assets.nu select-release

let complete = [
    {name: arm.zip}
    {name: x64.zip}
]

let releases = [
    {
        tag_name: v4
        draft: true
        prerelease: false
        assets: $complete
    }
    {
        tag_name: v3
        draft: false
        prerelease: false
        assets: []
    }
    {
        tag_name: v2-rc1
        draft: false
        prerelease: true
        assets: $complete
    }
    {
        tag_name: v2
        draft: false
        prerelease: false
        assets: [
            {name: arm.zip}
        ]
    }
    {
        tag_name: v1
        draft: false
        prerelease: false
        assets: $complete
    }
]

assert equal (select-release $releases [arm.zip x64.zip]) v1

assert error { select-release [] [arm.zip] }

assert error { select-release ($releases | first 4) [arm.zip x64.zip] }

print "Release asset selection checks passed"
