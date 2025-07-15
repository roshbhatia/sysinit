((block_scalar) @injection.content
        (#contains? @injection.content "#!/usr/bin/env bash")
        (#set! injection.language "bash"))