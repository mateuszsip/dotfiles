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
      -- shifted jkl; layout (see config/keymaps.lua): J/: = jump back/forward.
      -- H takes return-to-parent so J is not bound to two actions (the
      -- plugin's own default has that bug: jump_back and parent both on H).
      jump_back = "J",
      jump_down = "K",
      jump_up = "L",
      jump_forward = ":",
      return_to_parent_table = "H",
    },
  },
}
