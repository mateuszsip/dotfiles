return {
  "letieu/jira.nvim",
  opts = {
    jira = {
      limit = 200,
    },
    active_sprint_query = "project = '%s' AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done AND assignee is not EMPTY ORDER BY Rank ASC",
    active_sprint_status_order = { "QA", "Review", "In Progress", "Pending", "Blocked", "To Do", "Signed off" },
    -- Maps board column names to actual Jira API status names
    active_sprint_status_map = {
      ["Review"] = "Awaiting review",
    },
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
  config = function(_, opts)
    require("jira").setup(opts)

    local status_index = {}
    local status_map = opts.active_sprint_status_map or {}
    for i, s in ipairs(opts.active_sprint_status_order or {}) do
      status_index[status_map[s] or s] = i
    end

    local sprint = require("jira.jira-api.sprint")
    local orig = sprint.get_active_sprint_issues
    sprint.get_active_sprint_issues = function(project, callback)
      orig(project, function(issues, err)
        if issues and not err then
          for _, issue in ipairs(issues) do
            issue.parent = nil
          end
          table.sort(issues, function(a, b)
            return (status_index[a.status] or 999) < (status_index[b.status] or 999)
          end)
        end
        callback(issues, err)
      end)
    end
  end,
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
