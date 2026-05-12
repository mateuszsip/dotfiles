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

-- Strip <h4>…</h4> HTML tags from Octo's details-fold virtual text.
-- These tags come from GitHub Actions <details><summary><h4>name</h4></summary> blocks.
-- Octo renders fold summaries as overlay extmarks — matchadd/syntax can't touch them.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "octo",
  callback = function(ev)
    local buf = ev.buf
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then return end
      local details_ns = vim.api.nvim_create_namespace("octo_details_folds")
      local extmarks = vim.api.nvim_buf_get_extmarks(buf, details_ns, 0, -1, { details = true })
      for _, extmark in ipairs(extmarks) do
        local id, row, details = extmark[1], extmark[2], extmark[4]
        if not (details and details.virt_text) then goto continue end
        local changed = false
        for _, chunk in ipairs(details.virt_text) do
          local cleaned = chunk[1]:gsub("</?h%d>", "")
          if cleaned ~= chunk[1] then chunk[1] = cleaned; changed = true end
        end
        if changed then
          vim.api.nvim_buf_set_extmark(buf, details_ns, row, 0, {
            id = id,
            virt_text = details.virt_text,
            virt_text_pos = details.virt_text_pos,
            line_hl_group = details.line_hl_group,
          })
        end
        ::continue::
      end
    end)
  end,
})

return {
  "pwntester/octo.nvim",
  opts = {
    enable_builtin = true,
    default_to_projects_v2 = true,
    default_merge_method = "squash",
    picker = "snacks",
    picker_config = {
      snacks = {
        actions = {
          search = {
            {
              name = "close_pr",
              lhs = "<C-x>",
              desc = "close pull request",
              mode = { "n", "i" },
              fn = function(picker, item)
                if item.kind ~= "pull_request" then
                  return
                end
                local gh = require "octo.gh"
                local utils = require "octo.utils"
                gh.pr.close {
                  item.number,
                  repo = item.repository.nameWithOwner,
                  opts = {
                    cb = function(output, stderr)
                      local msg = (not utils.is_blank(output) and output)
                        or (not utils.is_blank(stderr) and stderr)
                      if msg then
                        utils.info(msg)
                      end
                      vim.schedule(function()
                        for i, it in ipairs(picker.opts.items) do
                          if it == item then
                            table.remove(picker.opts.items, i)
                            break
                          end
                        end
                        picker:refresh()
                      end)
                    end,
                  },
                }
              end,
            },
            {
              name = "toggle_draft",
              lhs = "<C-d>",
              desc = "toggle draft / ready for review",
              mode = { "n", "i" },
              fn = function(picker, item)
                if item.kind ~= "pull_request" then
                  return
                end
                local gh = require "octo.gh"
                local utils = require "octo.utils"
                -- gh pr ready outputs success to stderr (known quirk), so show both
                gh.pr.ready {
                  item.number,
                  repo = item.repository.nameWithOwner,
                  undo = not item.isDraft,
                  opts = {
                    cb = function(output, stderr)
                      local msg = (not utils.is_blank(stderr) and stderr)
                        or (not utils.is_blank(output) and output)
                      if msg then
                        utils.info(msg)
                      end
                      vim.schedule(function()
                        item.isDraft = not item.isDraft
                        picker:refresh()
                      end)
                    end,
                  },
                }
              end,
            },
          },
        },
      },
    },
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
