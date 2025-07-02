;; Injections for Go templates in YAML (Crossplane compositions)

;; Inject Go templates in any multiline string containing template syntax
((block_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

;; Inject Go templates in regular strings containing template syntax
((string_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#contains? @injection.content "}}")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

;; Inject Go templates in specific Crossplane fields that commonly use templates
((block_scalar) @injection.content
  (#any-of? @injection.content
    (key_scalar "fromFieldPath")
    (key_scalar "toFieldPath")
    (key_scalar "string")
    (key_scalar "fmt")
    (key_scalar "base64")
    (key_scalar "value")
  )
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

