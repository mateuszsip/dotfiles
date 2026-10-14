-- Readout for CodeCompanion chat buffers: adapter, model, context usage, cost.
-- Shown in two places: the lualine statusline (registered from
-- plugins/lualine.lua) and a window-local winbar set here, so the numbers
-- stay visible even when the statusline is crowded or shows a stale render.
-- ACP chats only: usage comes from the agent's usage_update, captured in full
-- ({used, size, cost?}) by utils.cc_acp onto chat.cc_usage. Upstream only
-- keeps `used` as chat.tokens, so fall back to that when no update arrived yet
-- (or the agent never sends one). The model comes from the ACP session config.
local M = {}

local function fmt_tokens(n)
  if n >= 1000000 then
    return string.format("%.1fM", n / 1000000)
  elseif n >= 1000 then
    return string.format("%.1fk", n / 1000)
  end
  return tostring(n)
end

local function fmt_cost(cost)
  if type(cost) ~= "table" or type(cost.amount) ~= "number" or cost.amount == 0 then
    return nil
  end
  if cost.currency and cost.currency ~= "" and cost.currency ~= "USD" then
    return string.format("%g %s", cost.amount, cost.currency)
  end
  return string.format("$%g", cost.amount)
end

local function chat_for(bufnr)
  local ok, cc = pcall(require, "codecompanion")
  if not ok or not cc then
    return nil
  end
  local ok2, chat = pcall(cc.buf_get_chat, bufnr or 0)
  return ok2 and chat or nil
end

local function current_chat()
  if vim.bo.filetype ~= "codecompanion" then
    return nil
  end
  return chat_for(0)
end

---Build the readout string for a chat object. Pure: safe to call for any buffer.
function M.text(chat)
  if not chat then
    return ""
  end
  local parts = { chat.adapter and chat.adapter.formatted_name or "?" }

  local conn = chat.acp_connection
  local ok, models = pcall(function()
    return conn and conn:get_models()
  end)
  if ok and models and models.currentModelId then
    local name = models.currentModelId
    if type(models.availableModels) == "table" then
      for _, m in ipairs(models.availableModels) do
        if m.modelId == models.currentModelId then
          name = m.name or name
          break
        end
      end
    end
    table.insert(parts, name)
  end

  local usage = chat.cc_usage
  if type(usage) == "table" and type(usage.used) == "number" then
    if type(usage.size) == "number" and usage.size > 0 then
      table.insert(
        parts,
        string.format("%s/%s (%d%%)", fmt_tokens(usage.used), fmt_tokens(usage.size), math.floor(usage.used / usage.size * 100 + 0.5))
      )
    else
      table.insert(parts, fmt_tokens(usage.used) .. " tok")
    end
    local cost = fmt_cost(usage.cost)
    if cost then
      table.insert(parts, cost)
    end
  elseif type(chat.tokens) == "number" then
    table.insert(parts, fmt_tokens(chat.tokens) .. " tok")
  end
  return table.concat(parts, " · ")
end

function M.cond()
  return current_chat() ~= nil
end

function M.component()
  return M.text(current_chat())
end

-- Window-local winbar: repaint every chat window with its own buffer's readout.
-- The winbar interprets % codes, so escape literal % (e.g. "44%").
local function refresh_winbar()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and vim.bo[buf].filetype == "codecompanion" then
      local s = M.text(chat_for(buf))
      if s ~= "" then
        vim.w[win].cc_winbar = true
        vim.wo[win].winbar = " " .. s:gsub("%%", "%%%%") .. " "
      end
    end
  end
end

local function clear_winbar(win)
  if vim.w[win].cc_winbar then
    vim.w[win].cc_winbar = nil
    pcall(vim.api.nvim_set_option_value, "winbar", "", { scope = "local", win = win })
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("cc_status", { clear = true })

  local function refresh_all()
    refresh_winbar()
    vim.schedule(function()
      pcall(function()
        require("lualine").refresh()
      end)
    end)
  end

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = {
      "CodeCompanionChatDone",
      "CodeCompanionChatSubmitted",
      "CodeCompanionChatACPModeChanged",
      "CodeCompanionChatCleared",
      "CodeCompanionUsageUpdate",
    },
    callback = refresh_all,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "codecompanion",
    callback = refresh_all,
  })

  -- Repaint on focus (covers a stale statusline render), and clear when the
  -- window moves on to a non-chat buffer so a dead readout doesn't linger.
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "codecompanion" then
        refresh_all()
      else
        clear_winbar(vim.api.nvim_get_current_win())
      end
    end,
  })
end

return M
