return {
  "letieu/jira.nvim",
  opts = {
    jira = {
      limit = 200,
    },
    active_sprint_query = "project = '%s' AND labels in (Platform, DevOps, Scalability, Technical) AND statusCategory != Done AND assignee is not EMPTY ORDER BY created DESC, Rank ASC",
    active_sprint_status_order = { "QA", "Review", "In Progress", "Pending", "Blocked", "To Do", "Signed off" },
    -- Maps board column names to actual Jira API status names
    active_sprint_status_map = {
      ["QA"] = "Needs QA",
      ["Review"] = "Awaiting review",
    },
    -- Background colors using flexoki-400 accents; text is always cream (#FFFCF0)
    status_colors = {
      ["Needs QA"]        = "#3AA99F", -- cyan
      ["Awaiting review"] = "#8B7EC8", -- purple
      ["In Progress"]     = "#D0A215", -- yellow
      ["Pending"]         = "#DA702C", -- orange
      ["To Do"]           = "#4385BE", -- blue
      ["Signed off"]      = "#879A39", -- green
      ["Closed"]          = "#878580", -- grey
      ["Blocked"]         = "#D14D41", -- red
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

    local ui = require("jira.board.ui")
    local orig_hl = ui.get_status_hl
    local status_colors = opts.status_colors or {}
    ui.get_status_hl = function(status_name)
      local bg = status_colors[status_name]
      if bg then
        local board_state = require("jira.board.state")
        local hl_name = "JiraStatus_" .. (status_name or ""):gsub("%s+", "_"):gsub("[^%w_]", "")
        if not board_state.status_hls[status_name] then
          vim.api.nvim_set_hl(0, hl_name, { fg = "#FFFCF0", bg = bg, bold = true })
          board_state.status_hls[status_name] = hl_name
        end
        return hl_name
      end
      return orig_hl(status_name)
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
            local sa = status_index[a.status] or 999
            local sb = status_index[b.status] or 999
            if sa ~= sb then return sa < sb end
            return (a.assignee or "") < (b.assignee or "")
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
