(block_scalar
  (comment) @injection.language
  @injection.content
  (#offset! @injection.language 0 2 0 0)
  (#offset! @injection.content 1 0 0 0)
  (#set! injection.include-children)
)

(block_scalar) @injection.content
  (#set! injection.language "yaml")
  (#set! injection.include-children)
