-- Report CodeCompanion chat state to the shared AI session store.
--
-- Waybar's `custom/ai` module and `sys-ai` read one JSON file per session from
-- $XDG_RUNTIME_DIR/ai (see ~/.config/waybar/ai-indicator.sh). This module is
-- the CodeCompanion reporter: every chat that is working, blocked on the user,
-- or finished-but-unread gets an entry, so the indicator can name the session
-- and `sys-ai` can jump straight to it.
--
-- The same states also reach the Rex terminal this nvim runs in, as OSC 7501
-- reports (the Program Status Protocol): rexia badges the tab, lists the chat
-- in the session's activity and hover card, and can notify when a turn needs
-- you. write() and remove() feed both sinks, so the store and the terminal
-- cannot disagree about a chat.
--
-- Statuses, by priority:
--   waiting  the agent is blocked on you (tool approval or a question)
--   done     the turn finished and has not been acknowledged
--   working  a request is in flight
--
-- `done` clears when you interact with the chat, switch to it, or return to a
-- focused terminal; `waiting` stays until the approval/question is answered,
-- so a glance at the buffer does not hide it.
-- Entries are pruned by the reader when their pid is gone, so a SIGKILLed
-- server does not leave a ghost in the indicator.
local M = {}

local api = vim.api

local dir -- resolved once, created on demand
local owned = {} -- bufnr -> { status = string, detail = string|nil }
local signal_timer

local function state_dir()
  if dir then
    return dir
  end
  local base = vim.env.XDG_RUNTIME_DIR
  dir = vim.env.AI_DIR or (((base and base ~= "") and base or "/tmp") .. "/ai")
  vim.fn.mkdir(dir, "p")
  return dir
end

local function path_for(bufnr)
  return state_dir() .. "/cc_" .. vim.fn.getpid() .. "_" .. bufnr .. ".json"
end

-- Coalesce the writes from one event burst into a single waybar refresh.
local function signal_waybar()
  if signal_timer then
    return
  end
  signal_timer = vim.uv.new_timer()
  signal_timer:start(
    50,
    0,
    vim.schedule_wrap(function()
      signal_timer:stop()
      signal_timer:close()
      signal_timer = nil
      vim.fn.jobstart({ "pkill", "-SIGRTMIN+11", "waybar" }, { detach = true })
    end)
  )
  signal_timer:unref()
end

local function chat_for(bufnr)
  local ok, cc = pcall(require, "codecompanion")
  if not ok or not cc then
    return nil
  end
  local ok2, chat = pcall(cc.buf_get_chat, bufnr)
  if ok2 and type(chat) == "table" and chat.bufnr then
    return chat
  end
  return nil
end

local function title_of(chat, bufnr)
  if type(chat.title) == "string" and chat.title ~= "" then
    return chat.title
  end
  local ok, chats = pcall(require, "utils.cc_chats")
  if ok and chats then
    local name = chats.display_name(chat)
    if name and name ~= "" then
      return name
    end
  end
  local ok2, registry = pcall(require, "codecompanion.interactions.shared.registry")
  local entry = ok2 and registry.get(bufnr) or nil
  return entry and entry.name or ("chat " .. bufnr)
end

-- The Rex sink: OSC 7501, the Program Status Protocol. A report is key=value
-- pairs joined with `:`, its free text (title, msg) base64, and each report
-- replaces its record completely, so every one repeats app and title. One
-- record per chat (id=cc-<bufnr>): a tab badges the most urgent of them, and
-- rexia's hover card lists each chat on its own line. Terminals ignore OSC
-- codes they don't know, so there is no feature detection; REX_SESSION
-- (Rex's marker that this shell runs inside one of its terminals) plus a tty
-- on stdout keeps headless and embedded instances quiet.
local rex_supported

local function rex_enabled()
  if rex_supported == nil then
    local session = vim.env.REX_SESSION
    rex_supported = session ~= nil and session ~= "" and vim.uv.guess_handle(1) == "tty"
  end
  return rex_supported
end

-- A report whose decoded text holds a control character is discarded whole,
-- and title and msg are capped at 192 and 2048 decoded bytes. Strip the
-- controls, then cut on a UTF-8 boundary so the base64 still decodes to
-- valid UTF-8.
local function rex_text(text, limit)
  if type(text) ~= "string" or text == "" then
    return nil
  end
  text = text:gsub("[%z\1-\31\127]", ""):gsub("\194[\128-\159]", "")
  if #text > limit then
    local cut = limit
    while cut > 0 and (text:byte(cut) or 0) >= 0x80 do
      cut = cut - 1
    end
    text = text:sub(1, cut)
  end
  if text == "" then
    return nil
  end
  return vim.base64.encode(text)
end

-- One write, flushed whole: the pty receives the sequence as one chunk, and
-- OSC never touches the screen grid, so the TUI's own output is unaffected.
local function rex_send(parts)
  io.stdout:write("\27]7501;" .. table.concat(parts, ":") .. "\27\\")
  io.stdout:flush()
end

local function rex_clear(bufnr)
  if rex_enabled() then
    rex_send({ "state=clear", "id=cc-" .. bufnr })
  end
end

local function rex_report(bufnr, status, detail, kind, title)
  if not rex_enabled() then
    return
  end
  -- A stopped turn is a cancel, not a result: the store still says done until
  -- seen, but a "Done" badge for a turn the user called off points at
  -- nothing. The protocol's advice for a cancel is idle; for one chat among
  -- several, removing its record says the same thing more precisely.
  if status == "done" and detail == "stopped" then
    rex_clear(bufnr)
    return
  end
  local state
  if status == "working" then
    state = "working"
  elseif status == "waiting" then
    state = "blocked"
  elseif status == "done" then
    state = "done"
  else
    return
  end
  local parts = { "state=" .. state, "id=cc-" .. bufnr, "app=codecompanion" }
  if state == "blocked" and (kind == "permission" or kind == "question") then
    parts[#parts + 1] = "kind=" .. kind
  end
  local b64 = rex_text(title, 192)
  if b64 then
    parts[#parts + 1] = "title=" .. b64
  end
  b64 = rex_text(detail, 2048)
  if b64 then
    parts[#parts + 1] = "msg=" .. b64
  end
  rex_send(parts)
end

local function write(bufnr, status, detail, kind)
  local chat = chat_for(bufnr)
  if not chat then
    return
  end
  local previous = owned[bufnr]
  if previous and previous.status == status and previous.detail == detail and previous.kind == kind then
    return
  end

  local title = title_of(chat, bufnr)
  local entry = {
    id = "cc:" .. (vim.env.NV_SESSION_KEY or tostring(vim.fn.getpid())) .. ":" .. bufnr,
    tool = "codecompanion",
    status = status,
    title = title,
    detail = detail,
    cwd = vim.uv.cwd() or vim.fn.getcwd(),
    buf = bufnr,
    -- the server address `sys-ai` uses to reach the chat (usually set even
    -- without --listen on 0.12, where every instance has a default server)
    sock = vim.v.servername or "",
    pid = vim.fn.getpid(),
    ts = os.time(),
  }

  local path = path_for(bufnr)
  local tmp = path .. ".tmp"
  local f = io.open(tmp, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(entry))
  f:close()
  if not os.rename(tmp, path) then
    os.remove(tmp)
    return
  end

  owned[bufnr] = { status = status, detail = detail, kind = kind }
  signal_waybar()
  pcall(rex_report, bufnr, status, detail, kind, title)
end

local function remove(bufnr)
  local reported = owned[bufnr] ~= nil
  owned[bufnr] = nil
  -- BufDelete and BufWipeout fire for every buffer; only a chat we reported
  -- ever made a Rex record, and clearing one that was never set is noise.
  if reported then
    pcall(rex_clear, bufnr)
  end
  if os.remove(path_for(bufnr)) then
    signal_waybar()
  end
end

-- A chat you are interacting with no longer needs a "done" badge. `waiting`
-- is left alone: the prompt is still unanswered.
local function seen(bufnr)
  local entry = owned[bufnr]
  if entry and entry.status == "done" then
    remove(bufnr)
  end
end

-- Hyprland does not report focus to nvim in this terminal (t_fi is empty), so
-- FocusGained never fires. Ask the compositor which window is active instead:
-- resolve the terminal window that hosts nvim once, then compare it with the
-- active window. Returns nil when the compositor cannot answer.
local function hypr_json(args)
  local out = vim.fn.system(args)
  if vim.v.shell_error ~= 0 or out == "" then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, out)
  return ok and decoded or nil
end

local function parent_pid(pid)
  local f = io.open("/proc/" .. pid .. "/status")
  if not f then
    return nil
  end
  local ppid
  for line in f:lines() do
    ppid = line:match("^PPid:%s*(%d+)")
    if ppid then
      break
    end
  end
  f:close()
  return tonumber(ppid)
end

local function terminal_address()
  if M._terminal_address then
    return M._terminal_address
  end
  local clients = hypr_json({ "hyprctl", "clients", "-j" })
  if type(clients) ~= "table" then
    return nil
  end
  local by_pid = {}
  for _, client in ipairs(clients) do
    if client.pid and client.address then
      by_pid[client.pid] = client.address
    end
  end
  local pid = vim.fn.getpid()
  for _ = 1, 32 do
    if by_pid[pid] then
      M._terminal_address = by_pid[pid]
      return M._terminal_address
    end
    pid = parent_pid(pid)
    if not pid or pid <= 1 then
      return nil
    end
  end
  return nil
end

local function terminal_focused()
  local address = terminal_address()
  if not address then
    return nil
  end
  local win = hypr_json({ "hyprctl", "activewindow", "-j" })
  if type(win) ~= "table" then
    return nil
  end
  return win.address == address
end

local function has_done()
  for _, entry in pairs(owned) do
    if entry.status == "done" then
      return true
    end
  end
  return false
end

-- t_fi is empty under ghostty, so FocusGained is not delivered. Retire a done
-- badge once the terminal is focused and the chat buffer is current: CursorHold
-- gives us a periodic check while idle, CursorMoved covers interaction.
local focus_timer
local function check_seen()
  if focus_timer or not has_done() then
    return
  end
  focus_timer = vim.uv.new_timer()
  focus_timer:start(
    200,
    0,
    vim.schedule_wrap(function()
      focus_timer:stop()
      focus_timer:close()
      focus_timer = nil
      if terminal_focused() == false then
        return
      end
      seen(api.nvim_get_current_buf())
    end)
  )
  focus_timer:unref()
end

--- Status currently reported for a chat buffer (nil when idle/unreported).
---@param bufnr integer
---@return string|nil
function M.status(bufnr)
  local entry = owned[bufnr]
  return entry and entry.status or nil
end

--- Open a chat buffer from `nvim --server ... --remote-expr` (used by sys-ai).
---@param bufnr integer
---@return integer 1 on success
function M.focus(bufnr)
  if type(bufnr) ~= "number" or not api.nvim_buf_is_valid(bufnr) then
    return 0
  end
  local ok = pcall(function()
    require("codecompanion").restore(bufnr)
  end)
  return ok and 1 or 0
end

function M.setup()
  if M._setup then
    return
  end
  -- waybar + sys-ai are Linux-only; skip the store on macOS rather than
  -- leaving unreachable files in /tmp
  if vim.fn.has("linux") == 0 then
    return
  end
  M._setup = true

  local group = api.nvim_create_augroup("cc_notify", { clear = true })

  api.nvim_create_autocmd("User", {
    group = group,
    pattern = {
      "CodeCompanionChatSubmitted",
      "CodeCompanionToolApprovalRequested",
      "CodeCompanionToolQuestionAsked",
      "CodeCompanionToolApprovalFinished",
      "CodeCompanionToolQuestionAnswered",
      "CodeCompanionChatDone",
      "CodeCompanionChatStopped",
      "CodeCompanionChatCleared",
      "CodeCompanionChatClosed",
    },
    callback = function(args)
      local data = args.data or {}
      local bufnr = data.bufnr
      if type(bufnr) ~= "number" then
        return
      end

      if args.match == "CodeCompanionChatSubmitted" then
        write(bufnr, "working")
      elseif args.match == "CodeCompanionToolApprovalRequested" then
        -- kind: the Rex report says what a blocked chat waits for
        write(bufnr, "waiting", data.name, "permission")
      elseif args.match == "CodeCompanionToolQuestionAsked" then
        write(bufnr, "waiting", data.header or data.question, "question")
      elseif args.match == "CodeCompanionToolApprovalFinished" or args.match == "CodeCompanionToolQuestionAnswered" then
        write(bufnr, "working")
      elseif args.match == "CodeCompanionChatDone" or args.match == "CodeCompanionChatStopped" then
        write(bufnr, "done", args.match == "CodeCompanionChatStopped" and "stopped" or nil)
      else -- ChatCleared, ChatClosed
        remove(bufnr)
      end
    end,
  })

  api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function(args)
      seen(args.buf)
    end,
  })

  -- FocusGained does not fire under ghostty (t_fi is empty); interaction is
  -- the reliable "I am back" signal.
  api.nvim_create_autocmd({ "CursorMoved", "CursorHold" }, {
    group = group,
    callback = check_seen,
  })

  -- Coming back to the terminal from another window should retire the badge
  -- even if the chat buffer was already current.
  api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      seen(api.nvim_get_current_buf())
    end,
  })

  api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for bufnr in pairs(owned) do
        remove(bufnr)
      end
    end,
  })

  -- `:bd`/`:bwipeout` do not always go through Chat:close()
  api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(args)
      remove(args.buf)
    end,
  })
end

return M
