return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      bind_to_cwd = true,
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
      },
    },
    window = {
      mappings = {
        ["<leader>sf"] = {
          function(state)
            local node = state.tree:get_node()
            local dir = node.type == "directory" and node.path
              or vim.fn.fnamemodify(node.path, ":h")
            Snacks.picker.files({ cwd = dir })
          end,
          desc = "find files in node dir",
        },
        ["<leader>sg"] = {
          function(state)
            local node = state.tree:get_node()
            local dir = node.type == "directory" and node.path
              or vim.fn.fnamemodify(node.path, ":h")
            Snacks.picker.grep({ cwd = dir })
          end,
          desc = "grep in node dir",
        },
      },
    },
  },
}
