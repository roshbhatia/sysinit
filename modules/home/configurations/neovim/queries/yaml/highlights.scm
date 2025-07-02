
; Highlight Go template delimiters in YAML block, plain, and quoted scalars

(block_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")

(plain_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")

(double_quote_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")

(single_quote_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")


