((block_scalar) @injection.content
        (#contains? @injection.content "{{")
        (#set! injection.language "gotmpl"))
((plain_scalar) @injection.content
        (#contains? @injection.content "{{")
        (#set! injection.language "gotmpl"))