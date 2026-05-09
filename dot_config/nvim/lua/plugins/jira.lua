return {
  "letieu/jira.nvim",
  opts = {
    jira = {
      limit = 200,
    },
    active_sprint_query = "project = '%s' AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done ORDER BY created DESC, Rank ASC",
    queries = {
      ["All platform"] = "project = '%s' AND labels in (Platform, DevOps, Scalability, Technical) ORDER BY created DESC, Rank ASC",
      ["All cards"] = "project = '%s' ORDER BY created DESC, Rank ASC",
      ["My board tasks"] = "assignee = currentUser() AND project = '%s' AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done ORDER BY created DESC, Rank ASC",
      ["My tasks"] = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
    },
    projects = {
      ["CARD"] = {
        custom_fields = { -- Custom field to display in markdown view
          { key = "customfield_11091", label = "T-shirt size" },
        },
      },
    },
  },
  keys = {
    { "<leader>jj", "<cmd>Jira CARD<CR>", desc = "Jira: Open CARD board" },
    {
      "<leader>ji",
      function()
        vim.ui.input({ prompt = "Issue key: ", default = "CARD-" }, function(key)
          if key and key ~= "" then
            vim.cmd("Jira info " .. key)
          end
        end)
      end,
      desc = "Jira: View issue",
    },
    {
      "<leader>je",
      function()
        vim.ui.input({ prompt = "Issue key: ", default = "CARD-" }, function(key)
          if key and key ~= "" then
            vim.cmd("Jira edit " .. key)
          end
        end)
      end,
      desc = "Jira: Edit issue",
    },
    { "<leader>jc", "<cmd>Jira create CARD<CR>", desc = "Jira: Create issue" },
    { "<leader>jl", "<cmd>Jira auth login<CR>", desc = "Jira: Auth login" },
    { "<leader>ja", "<cmd>Jira auth info<CR>", desc = "Jira: Auth info" },
  },
}
