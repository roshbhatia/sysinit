;; Highlights for YAML multiline strings that are Go templates
;; Highlight the key `template`
(key_scalar "template") @keyword

;; Highlight multiline strings associated with `template`
(block_scalar (key_scalar "template")) @template.string

;; General YAML nodes
(string_scalar) @string
(alias_scalar) @string
(anchor_scalar) @string

