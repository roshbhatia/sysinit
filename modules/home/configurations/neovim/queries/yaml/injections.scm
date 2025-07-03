;; Inject YAML with Go templates for Crossplane GoTemplate template field
;; This specifically targets the template field in GoTemplate resources
((block_mapping_pair
  key: (flow_node (plain_scalar) @_template_key (#eq? @_template_key "template"))
  value: (flow_node (block_scalar) @injection.content))
  (#set! injection.language "yaml")
  (#set! injection.combined)
  (#set! injection.include-children))

;; Fallback: Inject gotmpl for any multiline string containing Go template syntax
((block_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#not-contains? @injection.content "apiVersion")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

;; Inject gotmpl for regular strings with template syntax (non-YAML content)
((string_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#not-contains? @injection.content "apiVersion")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

((double_quote_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#not-contains? @injection.content "apiVersion")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

((single_quote_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#not-contains? @injection.content "apiVersion")
  (#set! injection.language "gotmpl")
  (#set! injection.include-children))

;; Special case for inline YAML with Go templates
((plain_scalar) @injection.content
  (#contains? @injection.content "{{")
  (#contains? @injection.content "apiVersion")
  (#set! injection.language "yaml")
  (#set! injection.combined)
  (#set! injection.include-children))

