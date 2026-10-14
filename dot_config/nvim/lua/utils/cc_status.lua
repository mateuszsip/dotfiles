-- Statusline component for CodeCompanion chat buffers: adapter, model, context tokens.
-- ACP chats only: tokens come from the agent's usage_update (chat.tokens), the model
-- from the ACP session config options.
local M = {}

local function fmt_tokens(n)
  if n >= 1000000 then
    return string.format("%.1fM", n / 1000000)
  elseif n >= 1000 then
    return string.format("%.1fk", n / 1000)
  end
  return tostring(n)
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

  if type(chat.tokens) == "number" then
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
    },
    callback = function()
      vim.schedule(function()
        require("lualine").refresh()
      end)
    end,
  })
end

return M
