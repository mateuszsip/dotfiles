; Full replacement (no ; extends) so PHP blocks aren't double-injected.
; Non-PHP fenced blocks: use the info-string language name as-is.
((fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)
 (#not-match? @injection.language "^php$"))

; PHP fenced blocks: inject php_only (pure PHP, no <?php wrapper).
; Offset by 1 row to skip the opening <?php line.
((fenced_code_block
  (info_string
    (language) @_lang)
  (code_fence_content) @injection.content)
 (#eq? @_lang "php")
 (#offset! @injection.content 1 0 0 0)
 (#set! injection.language "php_only"))

; HTTP blocks via kulala.
((fenced_code_block
  (info_string
    (language) @_lang)
  (code_fence_content) @injection.content)
 (#eq? @_lang "http")
 (#set! injection.language "kulala_http"))

((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
