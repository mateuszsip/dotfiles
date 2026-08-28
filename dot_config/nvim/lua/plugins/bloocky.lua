return {
  "atiladefreitas/bloocky",
  cmd = {
    "Bloocky",
    "BloockyToggle",
    "BloockySidebar",
    "BloockySidebarToggle",
    "BloockyAdd",
    "BloockySync",
    "BloockySyncAuth",
    "BloockySyncStatus",
  },
  keys = {
    { "<leader>tb", "<cmd>BloockyToggle<cr>", desc = "Calendar" },
    { "<leader>tB", "<cmd>BloockySidebarToggle<cr>", desc = "Calendar (sidebar)" },
  },
  opts = {
    default_view = "week",
    week_start = "monday",
    sync = {
      enabled = vim.env.BLOOCKY_GOOGLE_CLIENT_ID ~= nil,
      accounts = {
        {
          id = "gcal",
          provider = "google",
          client_id = vim.env.BLOOCKY_GOOGLE_CLIENT_ID,
          client_secret_cmd = { "sh", "-c", "printf %s \"$BLOOCKY_GOOGLE_CLIENT_SECRET\"" },
          -- Which calendars to sync. The first rw one is where new blocks are
          -- created; ro = displayed only, never written to.
          calendars = {
            { name = "Work", mode = "rw", default = true },
            { name = "Personal", mode = "rw" },
            -- { name = "Birthdays", mode = "ro" },
          },
        },
      },
    },
    integrations = {
      dooing = {
        enabled = true,
      },
    },
  },
}
