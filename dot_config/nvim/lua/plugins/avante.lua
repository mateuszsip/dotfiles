return {
  "yetone/avante.nvim",
  opts = {
    provider = "auggie",
    acp_providers = {
      ["auggie"] = {
        command = "auggie",
        args = {
          "--acp",
        },
      }
    }
  }
}
