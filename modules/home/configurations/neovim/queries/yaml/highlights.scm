;; Highlights for YAML multiline strings that are Go templates

;; Highlight the key `inline`
(key_scalar "inline") @keyword

;; Highlight multiline strings associated with `inline`
(block_scalar (key_scalar "inline")) @template.string

;; General YAML nodes
(string_scalar) @string
(alias_scalar) @string
(anchor_scalar) @string

