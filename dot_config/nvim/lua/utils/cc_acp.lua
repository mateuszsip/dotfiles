-- opencode persists a session the moment an ACP client calls session/new --
-- before any prompt is sent -- and nothing deletes it when that session is
-- abandoned (https://github.com/anomalyco/opencode/issues/38064; opencode's
-- TUI only persists on the first prompt). CodeCompanion calls session/new as
-- soon as a chat buffer opens, so every chat that is closed without a
-- prompt, and every /resume (or utils.cc_chats restore) that replaces the
-- session, leaks an empty, title-less session into opencode's session list.
-- opencode supports ACP session/delete; CodeCompanion never sends it, so
-- patch the connection to delete the abandoned session at the exact points
-- it is dropped:
--   * a session/load replaced it (/resume, utils.cc_chats restore)
--   * the connection goes away with no prompt ever sent (Chat:close and
--     the plugin's VimLeavePre cleanup both funnel through
--     Connection:disconnect)
local M = {}

local DELETE = "session/delete"

-- Only send session/delete when the agent advertises it; other ACP agents
-- (claude_code, muse) don't and would just reply with an error
local function can_delete(conn)
  local caps = conn._agent_info and conn._agent_info.agentCapabilities
  return not not (caps and caps.sessionCapabilities and caps.sessionCapabilities.delete)
end

-- Best-effort delete. send_rpc_request waits for the reply, so the row is
-- durable-gone before Connection:disconnect kills the agent process right
-- after this returns.
local function delete_session(conn, session_id)
  if not can_delete(conn) then
    return
  end
  pcall(function()
    conn:send_rpc_request(DELETE, { sessionId = session_id })
  end)
end

function M.setup()
  local ok, Connection = pcall(require, "codecompanion.acp")
  if not ok or not Connection or Connection._cc_delete_abandoned then
    return
  end
  Connection._cc_delete_abandoned = true

  -- Remember whether the session this connection holds was created fresh by
  -- session/new (rather than adopted from session/load)
  local establish = Connection._establish_session
  Connection._establish_session = function(self)
    local previous = self.session_id
    local success = establish(self)
    self._cc_fresh_session = success
      and self.session_id ~= nil
      and (previous == nil or self.session_id ~= previous)
    return success
  end

  -- Remember whether any prompt was ever sent: prompted sessions hold
  -- messages, so they are always kept
  local prompt = Connection.session_prompt
  Connection.session_prompt = function(self, messages)
    self._cc_prompted = true
    return prompt(self, messages)
  end

  -- /resume (and utils.cc_chats restore) load another session over the one
  -- the chat opened with: delete that now-abandoned session
  local load = Connection.load_session
  Connection.load_session = function(self, session_id, opts)
    local abandoned = self.session_id
    local success = load(self, session_id, opts)
    if success and abandoned and abandoned ~= self.session_id and not self._cc_prompted then
      delete_session(self, abandoned)
    end
    return success
  end

  -- Delete a never-prompted, freshly-created session before the agent
  -- process is torn down
  local disconnect = Connection.disconnect
  Connection.disconnect = function(self)
    if self._cc_fresh_session and self.session_id and not self._cc_prompted and self._state.handle then
      delete_session(self, self.session_id)
    end
    return disconnect(self)
  end

  -- Capture the full ACP usage_update ({used, size, cost?}) onto the chat.
  -- Upstream only keeps `used` (chat.tokens) and drops `size`/`cost`
  -- (acp/init.lua DISPATCH), so stash the whole payload for the statusline
  -- and refresh it live.
  if not Connection._cc_capture_usage then
    Connection._cc_capture_usage = true
    local handle_incoming = Connection.handle_incoming_request_or_notification
    Connection.handle_incoming_request_or_notification = function(self, notification)
      local result = handle_incoming(self, notification)
      local params = type(notification) == "table" and notification.params or nil
      local update = params and params.update or nil
      if
        type(notification) == "table"
        and notification.method == "session/update"
        and type(update) == "table"
        and update.sessionUpdate == "usage_update"
        and update.used
      then
        local chat
        if self.get_chat then
          pcall(function()
            chat = self:get_chat(params.sessionId)
          end)
        end
        chat = chat or self.chat
        if chat then
          chat.cc_usage = { used = update.used, size = update.size, cost = update.cost }
          vim.schedule(function()
            pcall(vim.api.nvim_exec_autocmds, "User", {
              pattern = "CodeCompanionUsageUpdate",
              modeline = false,
            })
          end)
        end
      end
      return result
    end
  end
end

return M
