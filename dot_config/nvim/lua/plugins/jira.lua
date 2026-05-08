return {
  "letieu/jira.nvim",
  opts = {
    jira = {
      limit = 200,
    },
    queries = {
      ["Next sprint"] = "project = '%s' AND sprint in futureSprints() ORDER BY Rank ASC",
      ["Backlog"] = "project = '%s' AND (issuetype IN standardIssueTypes() OR issuetype = Sub-task) AND (sprint IS EMPTY OR sprint NOT IN openSprints()) AND statusCategory != Done ORDER BY Rank ASC",
      ["My Tasks"] = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
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
    { "<leader>jl", "<cmd>Jira auth login<CR>",  desc = "Jira: Auth login" },
    { "<leader>ja", "<cmd>Jira auth info<CR>",   desc = "Jira: Auth info" },
  },
}
