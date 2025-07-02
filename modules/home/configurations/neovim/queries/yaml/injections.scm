;; Injections for Go templates in YAML (Crossplane compositions)

;; Inject Go templates in any multiline string containing template syntax
((block_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

;; Inject Go templates in regular strings containing template syntax
((string_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

((double_quote_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

((single_quote_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

((plain_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

