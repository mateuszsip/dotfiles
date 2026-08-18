-- LazyVim's editor.dial extra provides the <C-a>/<C-x> maps and per-filetype
-- groups. These extra augends restore what add-subtract-ex.nvim used to handle.
return {
  "monaqa/dial.nvim",
  opts = function(_, opts)
    local augend = require("dial.augend")

    local function pair(a, b)
      return augend.constant.new({ elements = { a, b }, word = false, cyclic = true })
    end

    vim.list_extend(opts.groups.default, {
      pair("==", "!="),
      pair("<=", ">="),
      pair("++", "--"),
      augend.constant.new({ elements = { "yes", "no" }, word = true, cyclic = true }),
      augend.constant.new({ elements = { "on", "off" }, word = true, cyclic = true }),
      augend.constant.alias.alpha, -- a -> b
      augend.constant.alias.Alpha, -- A -> B
    })
  end,
}
