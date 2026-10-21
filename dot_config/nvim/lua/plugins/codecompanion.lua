-- Experimental: https://github.com/olimorris/codecompanion.nvim
-- Chat uses an ACP agent picked per machine: opencode2 when it's on PATH
-- (private laptop), otherwise Claude Code (work, subscription; needs
-- `npm i -g @agentclientprotocol/claude-agent-acp`). Muse is also selectable
-- per chat via the `muse` adapter below; Antigravity via `antigravity`
-- (personal machines only). Inline/cmd interactions only
-- support HTTP adapters, so they stay on Copilot.
local chat_adapter = vim.fn.executable("opencode") == 1 and "opencode" or "claude_code"

-- MCP servers (stdio only). Jira/Datadog are remote HTTP servers reached via the
-- mcp-remote bridge (browser OAuth on first start) and only enabled on work machines.
local mcp_servers = {
  github = {
    cmd = { "docker", "run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server" },
    -- no `env` here: ACP adapters receive it raw (the `cmd:` prefix isn't resolved), so the
    -- token is inherited from the shell instead (nushell exports it from `gh auth token`)
  },
}
-- machine.lua is rendered by chezmoi (work_machine flag); absent until `chezmoi apply`
local has_machine, machine = pcall(require, "machine")
local is_work = has_machine and machine.work == true
if is_work then
  mcp_servers.jira = { cmd = { "npx", "-y", "mcp-remote", "https://mcp.atlassian.com/v2/mcp" } }
  mcp_servers.datadog = { cmd = { "npx", "-y", "mcp-remote", "https://mcp.datadoghq.com/v1/mcp" } }
end

return {
  {
    "olimorris/codecompanion.nvim",
    version = "^19.0.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    init = function()
      require("utils.cc_chats").setup()
      require("utils.cc_sessions").setup()
      require("utils.cc_acp").setup()
    end,
    cmd = {
      "CodeCompanion",
      "CodeCompanionChat",
      "CodeCompanionActions",
      "CodeCompanionCmd",
      "CodeCompanionCodeReview",
    },
    keys = {
      { "<leader>az", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "x" }, desc = "CodeCompanion Chat" },
      { "<leader>an", ":CodeCompanionChat<cr>", mode = { "n", "x" }, desc = "CodeCompanion New Chat" },
      {
        "<leader>at",
        function()
          -- /rename is HTTP-only, but Chat:set_title works for ACP chats too
          local cc = require("codecompanion")
          local chat = cc.buf_get_chat(0) or cc.last_chat()
          if not chat then
            return vim.notify("No CodeCompanion chat to rename", vim.log.levels.WARN)
          end
          vim.ui.input({ prompt = "Chat title: ", default = chat.title or "" }, function(input)
            if input and input ~= "" then
              chat:set_title(input)
              -- the snacks action palette lists chats by registry name ("Chat N"), not title
              require("codecompanion.interactions.shared.registry").update(chat.bufnr, { name = input })
            end
          end)
        end,
        desc = "CodeCompanion Rename Chat",
      },
      {
        "<leader>al",
        function()
          local function chat_entries()
            return vim.tbl_filter(function(e)
              return e.interaction == "chat"
            end, require("codecompanion.interactions.shared.registry").list())
          end
          if #chat_entries() == 0 then
            return vim.notify("No open CodeCompanion chats", vim.log.levels.INFO)
          end
          Snacks.picker({
            title = "Open chats (<m-d> close)",
            finder = function()
              return vim.tbl_map(function(e)
                local lines = vim.api.nvim_buf_get_lines(e.bufnr, 0, -1, false)
                -- prefer the chat title (set by <leader>at or the agent's session_info_update)
                local chat = require("codecompanion").buf_get_chat(e.bufnr)
                local title = chat and chat.title ~= "" and chat.title or e.name
                return { text = title, entry = e, preview = { text = table.concat(lines, "\n"), ft = "codecompanion" } }
              end, chat_entries())
            end,
            actions = {
              close_chat = function(picker, item)
                if not item then
                  return
                end
                local chat = require("codecompanion").buf_get_chat(item.entry.bufnr)
                if chat then
                  chat:close()
                end
                picker:find()
              end,
            },
            win = {
              input = {
                keys = {
                  ["<m-d>"] = { "close_chat", mode = { "i", "n" } },
                },
              },
              list = {
                keys = {
                  ["<m-d>"] = "close_chat",
                },
              },
            },
            preview = "preview",
            format = function(item)
              return { { item.text } }
            end,
            confirm = function(picker, item)
              picker:close()
              if item then
                -- the picker restores focus to the previous window on close, so open and focus afterwards
                vim.schedule(function()
                  item.entry.open()
                  local win = vim.fn.bufwinid(item.entry.bufnr)
                  if win ~= -1 then
                    vim.api.nvim_set_current_win(win)
                  end
                end)
              end
            end,
          })
        end,
        desc = "CodeCompanion Open Chats",
      },
      {
        "<leader>aL",
        function()
          require("utils.cc_chats").restore()
        end,
        desc = "CodeCompanion Restore Last Chats",
      },
      {
        "<leader>aq",
        function()
          local cc = require("codecompanion")
          local chat = cc.buf_get_chat(0) or cc.last_chat()
          if not chat then
            return vim.notify("No CodeCompanion chat to close", vim.log.levels.WARN)
          end
          -- move to the next chat (same order as `}`) before closing this one
          if #cc.buf_get_chat() > 1 then
            require("codecompanion.interactions.chat.keymaps").next_chat.callback(chat)
          end
          chat:close()
        end,
        desc = "CodeCompanion Close Chat",
      },
      {
        "<leader>ax",
        function()
          local cc = require("codecompanion")
          local chat = cc.buf_get_chat(0) or cc.last_chat()
          if not (chat and (chat.current_request or chat.tool_orchestrator)) then
            return vim.notify("No CodeCompanion request in progress", vim.log.levels.INFO)
          end
          chat:stop()
        end,
        desc = "CodeCompanion Stop Request",
      },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "x" }, desc = "CodeCompanion Actions" },
      { "<leader>ai", ":CodeCompanion ", mode = { "n", "x" }, desc = "CodeCompanion Inline" },
      { "<leader>as", "<cmd>CodeCompanionChat Add<cr>", mode = "x", desc = "CodeCompanion Add Selection" },
      { "<leader>ar", "<cmd>CodeCompanionCodeReview<cr>", desc = "CodeCompanion Review Agent Changes" },
      { "<leader>aR", "<cmd>CodeCompanionCodeReview Branch<cr>", desc = "CodeCompanion Review Branch" },
      {
        "<leader>am",
        ":CodeCompanionCodeReview Comment<cr>",
        mode = { "n", "x" },
        desc = "CodeCompanion Review Comment",
      },
    },
    opts = {
      mcp = {
        servers = mcp_servers,
        opts = { default_servers = vim.tbl_keys(mcp_servers) },
      },
      display = {
        chat = {
          fold_context = true,
        },
      },
      adapters = {
        acp = {
          opencode = function()
            return require("codecompanion.adapters").extend("opencode", {
              commands = { default = { "opencode", "acp" } },
              defaults = { mcpServers = "inherit_from_config" },
            })
          end,
          claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              defaults = { mcpServers = "inherit_from_config" },
            })
          end,
          -- Muse speaks MSP, not ACP, so this goes through the muse-acp
          -- bridge (installed by run_onchange_install-muse-acp.sh.tmpl);
          -- run `muse login` once first. Selectable, never the default.
          muse = function()
            return {
              name = "muse",
              formatted_name = "Muse",
              type = "acp",
              roles = {
                llm = "assistant",
                user = "user",
              },
              opts = {
                vision = true,
              },
              commands = {
                default = { "muse-acp" },
              },
              defaults = {
                auth_method = "muse-login",
                mcpServers = {},
                timeout = 20000, -- 20 seconds
              },
              parameters = {
                protocolVersion = 1,
                clientCapabilities = {
                  fs = { readTextFile = true, writeTextFile = true },
                },
                clientInfo = {
                  name = "CodeCompanion.nvim",
                  version = "1.0.0",
                },
              },
              handlers = {
                setup = function(self)
                  return true
                end,
                form_messages = function(self, messages, capabilities)
                  return require("codecompanion.adapters.acp.helpers").form_messages(self, messages, capabilities)
                end,
                on_exit = function(self, code) end,
              },
            }
          end,
          -- `agy` has no native `--acp` flag, so this goes through the
          -- antigravity-acp bridge (installed by
          -- run_onchange_install-antigravity-acp.sh.tmpl, personal machines
          -- only); run `agy login` once first. Selectable, never the default.
          -- `nil` on work machines drops the key, hiding the adapter.
          antigravity = not is_work
              and function()
                return {
                  name = "antigravity",
                  formatted_name = "Antigravity",
                  type = "acp",
                  roles = {
                    llm = "assistant",
                    user = "user",
                  },
                  opts = {
                    vision = true,
                  },
                  commands = {
                    default = { "agy-acp" },
                  },
                  defaults = {
                    mcpServers = {},
                    timeout = 20000, -- 20 seconds
                  },
                  parameters = {
                    protocolVersion = 1,
                    clientCapabilities = {
                      fs = { readTextFile = true, writeTextFile = true },
                    },
                    clientInfo = {
                      name = "CodeCompanion.nvim",
                      version = "1.0.0",
                    },
                  },
                  handlers = {
                    setup = function(self)
                      return true
                    end,
                    form_messages = function(self, messages, capabilities)
                      return require("codecompanion.adapters.acp.helpers").form_messages(self, messages, capabilities)
                    end,
                    on_exit = function(self, code) end,
                  },
                }
              end
            or nil,
        },
      },
      interactions = {
        chat = {
          adapter = chat_adapter,
          keymaps = {
            -- default `gx` (clear chat) shadows Neovim's open-link mapping
            clear = { modes = { n = "gX" } },
          },
        },
        inline = { adapter = "copilot" },
        cmd = { adapter = "copilot" },
        code_review = {
          keymaps = {
            close = { modes = { n = "q" }, callback = "close", description = "Close review" },
          },
        },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = function(_, opts)
      opts.file_types = opts.file_types or { "markdown" }
      table.insert(opts.file_types, "codecompanion")
    end,
    ft = { "codecompanion" },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "ai", mode = { "n", "x" } },
        { "<leader>aS", group = "sidekick" },
      },
    },
  },
}
