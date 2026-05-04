local function octo_search(query)
  vim.cmd("Octo search " .. query)
end

local function get_repo()
  local repo = require("octo.utils").get_remote_name()
  if not repo or repo == "" then
    vim.notify("Not in a git repo with a GitHub remote", vim.log.levels.WARN)
    return nil
  end
  return repo
end

return {
  "pwntester/octo.nvim",
  opts = {
    enable_builtin = true,
    default_to_projects_v2 = true,
    default_merge_method = "squash",
  },
  keys = {
    -- Fix: `Octo pr search` is broken, use `Octo search` instead.
    -- Prefills query with editable input so you can tweak filters before running.
    {
      "<leader>gP",
      function()
        local repo = get_repo()
        if not repo then
          return
        end
        local default = "is:pr repo:" .. repo
        vim.ui.input({ prompt = "Octo search: ", default = default }, function(query)
          if query and query ~= "" then
            octo_search(query)
          end
        end)
      end,
      desc = "Search PRs (Octo)",
    },

    -- My open PRs (current repo)
    {
      "<leader>gm",
      function()
        local repo = get_repo()
        if repo then
          octo_search("is:pr is:open author:mateuszsip repo:" .. repo)
        end
      end,
      desc = "My open PRs (current repo)",
    },
    -- My open PRs (all repos)
    {
      "<leader>gM",
      function()
        octo_search("is:pr is:open author:mateuszsip")
      end,
      desc = "My open PRs (all repos)",
    },

    -- My PRs - all states (current repo)
    {
      "<leader>gn",
      function()
        local repo = get_repo()
        if repo then
          octo_search("is:pr author:mateuszsip repo:" .. repo)
        end
      end,
      desc = "My PRs - all (current repo)",
    },
    -- My PRs - all states (all repos)
    {
      "<leader>gN",
      function()
        octo_search("is:pr author:mateuszsip")
      end,
      desc = "My PRs - all (all repos)",
    },
  },
}
