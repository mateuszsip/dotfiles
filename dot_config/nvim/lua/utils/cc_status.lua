-- Statusline component for CodeCompanion chat buffers: adapter, model, context usage, cost.
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
  if type(cost) ~= "table" or type(cost.amount) ~= "number" then
    return nil
  end
  if cost.currency and cost.currency ~= "" and cost.currency ~= "USD" then
    return string.format("%g %s", cost.amount, cost.currency)
  end
  return string.format("$%g", cost.amount)
end

local function current_chat()
  if vim.bo.filetype ~= "codecompanion" then
    return nil
  end
  local ok, cc = pcall(require, "codecompanion")
  return ok and cc.buf_get_chat(0) or nil
end

function M.cond()
  return current_chat() ~= nil
end

function M.component()
  local chat = current_chat()
  if not chat then
    return ""
  end
  local parts = { chat.adapter and chat.adapter.formatted_name or "?" }

  local conn = chat.acp_connection
  local models = conn and conn:get_models()
  if models and models.currentModelId then
    local name = models.currentModelId
    for _, m in ipairs(models.availableModels) do
      if m.modelId == models.currentModelId then
        name = m.name or name
        break
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

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("cc_status", { clear = true }),
    pattern = {
      "CodeCompanionChatDone",
      "CodeCompanionChatSubmitted",
      "CodeCompanionChatACPModeChanged",
      "CodeCompanionChatCleared",
      "CodeCompanionUsageUpdate",
    },
    callback = function()
      vim.schedule(function()
        require("lualine").refresh()
      end)
    end,
  })
end

return M
