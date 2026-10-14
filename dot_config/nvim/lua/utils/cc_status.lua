-- Readout for CodeCompanion chat buffers: model, context usage, cost.
-- Shown in lualine (global statusline, bottom of the editor) for chat buffers
-- only, via M.component/M.cond registered from plugins/lualine.lua. A
-- window-local statusline can't work here: LazyVim uses laststatus=3 (single
-- global statusline), which silently ignores per-window values.
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
    return string.format("%.2f %s", cost.amount, cost.currency)
  end
  return string.format("$%.2f", cost.amount)
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
  -- Escape % for the statusline: "(11%)" would otherwise start an
  -- unbalanced %-group and lualine fails the whole refresh with E542.
  return M.text(current_chat()):gsub("%%", "%%%%")
end

function M.setup()
  local group = vim.api.nvim_create_augroup("cc_status", { clear = true })

  -- lualine repaints on its own events, but not on ours: nudge it when a
  -- chat finishes, is submitted/cleared, or a usage update lands.
  local function refresh_all()
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
end

return M
