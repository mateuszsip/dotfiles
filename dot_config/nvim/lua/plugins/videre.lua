return {
  "Owen-Dechow/videre.nvim",
  cmd = "Videre",
  dependencies = {
    "Owen-Dechow/graph_view_yaml_parser",
    "Owen-Dechow/graph_view_toml_parser",
    "a-usr/xml2lua.nvim",
  },
  opts = {
    keymaps = {
      jump_back = "J",
      jump_down = "K",
      jump_up = "L",
      jump_forward = ":",
      return_to_parent_table = "J",
    },
  },
}
