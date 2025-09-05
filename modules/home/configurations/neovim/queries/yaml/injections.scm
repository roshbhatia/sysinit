(block_mapping
  (block_mapping_pair
    key: (flow_node)
    value: (block_node
      (block_scalar
        (comment) @injection.language
      ) @injection.content
    )
  )
  (#set! injection.include-children)
  (#offset! @injection.language 0 2 0 0)
  (#offset! @injection.content 1 0 0 0)
)

(block_mapping
  (block_mapping_pair
    key: (flow_node)
    value: (block_node
      (block_scalar) @injection.content
    )
  )
  (#set! injection.language "yaml")
  (#set! injection.include-children)
)
