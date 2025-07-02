
; Inject Go template parser into YAML block, plain, and quoted scalars containing Go templates
(block_scalar) @gotmpl
  (#match? @gotmpl "{{[^{]*}}")
  (#set! injection.language "gotmpl")

(plain_scalar) @gotmpl
  (#match? @gotmpl "{{[^{]*}}")
  (#set! injection.language "gotmpl")

(double_quote_scalar) @gotmpl
  (#match? @gotmpl "{{[^{]*}}")
  (#set! injection.language "gotmpl")

(single_quote_scalar) @gotmpl
  (#match? @gotmpl "{{[^{]*}}")
  (#set! injection.language "gotmpl")
  (#set! injection.language "gotmpl")
