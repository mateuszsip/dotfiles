-- Agent status badge for lualine.
--
-- The AI session store ($XDG_RUNTIME_DIR/ai, one JSON file per session) is the
-- shared answer to "does an agent want me": waybar's `custom/ai` renders it and
-- `sys-ai` jumps from it. This module renders the same counts in the statusline,
-- so a turn that finishes while you are in another buffer is visible without
-- looking up at the bar. utils/cc_notify.lua writes the entries for
-- CodeCompanion chats; Claude Code and opencode still report through
-- ai-notify.sh into a plain counter (/tmp/ai-count), which counts as one done
-- session here too.
--
-- Statuses, by priority: waiting (agent is blocked on you), done (turn finished
-- and not yet seen), working (request in flight). Colours mirror waybar:
-- orange while something waits, olive when only acknowledgements are left,
-- muted while agents are merely busy.
local M = {}

local icons = { waiting = "●", done = "✓", working = "·" }
local order = { "waiting", "done", "working" }
local legacy_file = "/tmp/ai-count"

local watcher -- fs_event on the store directory
local timer -- slow poll, for the legacy counter and as a watcher fallback
local cache ---@type table<string, integer>|nil
local cache_at = 0
local last_sig ---@type string|nil

-- Same resolution as utils/cc_notify.lua and ~/.config/waybar/ai-indicator.sh.
local function state_dir()
  local base = vim.env.XDG_RUNTIME_DIR
  return vim.env.AI_DIR or (((base and base ~= "") and base or "/tmp") .. "/ai")
end

-- A session whose process is gone (SIGKILL, crash, logout) is a ghost. pid 0
-- means "could not be attributed" and is kept, as in the waybar reader.
local function alive(pid)
  if type(pid) ~= "number" or pid <= 0 then
    return true
  end
  -- uv.kill returns 0 on success and nil, err on failure; it does not raise.
  -- EPERM means the process exists but belongs to another user, so count it.
  local ok, rc, err = pcall(vim.uv.kill, pid, 0)
  if not ok then
    return false
  end
  return rc == 0 or rc == true or ((err or ""):match("EPERM") ~= nil)
end

local function read_entry(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local body = f:read("*a")
  f:close()
  local ok, entry = pcall(vim.json.decode, body)
  if not ok or type(entry) ~= "table" then
    return nil
  end
  return entry
end

--- Sessions in the shared store, newest first. Dead pids are skipped.
---@return table[]
function M.sessions()
  local dir = state_dir()
  local out = {}
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return out
  end
  while true do
    local name = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if name:match("%.json$") then
      local entry = read_entry(dir .. "/" .. name)
      if entry and alive(entry.pid) then
        out[#out + 1] = entry
      end
    end
  end
  table.sort(out, function(a, b)
    return (a.ts or 0) > (b.ts or 0)
  end)
  return out
end

local function counts()
  local n = { waiting = 0, done = 0, working = 0 }
  for _, session in ipairs(M.sessions()) do
    local status = session.status
    if status ~= "waiting" and status ~= "done" then
      status = "working"
    end
    n[status] = n[status] + 1
  end
  -- One legacy counter becomes one done session, never a count of turns: a
  -- single Claude/opencode turn can bump it twice (stop hook + notification).
  if vim.fn.filereadable(legacy_file) == 1 then
    local turns = tonumber(vim.fn.readfile(legacy_file)[1] or "") or 0
    if turns > 0 then
      n.done = n.done + 1
    end
  end
  return n
end

-- lualine calls the component and the cond on every refresh; one directory
-- scan per refresh would read the same files dozens of times per second while
-- typing. Short TTL, and the watcher drops the cache on any store change.
local function status()
  local now = vim.uv.now()
  if cache and now - cache_at < 500 then
    return cache
  end
  cache, cache_at = counts(), now
  return cache
end

local function refresh()
  cache = nil
  pcall(function()
    require("lualine").refresh()
  end)
end

local function signature(n)
  return table.concat({ n.waiting, n.done, n.working }, ":")
end

local function hl(name)
  local ok, color = pcall(function()
    return Snacks.util.color(name)
  end)
  return ok and color or nil
end

function M.component()
  local n = status()
  local parts = {}
  for _, name in ipairs(order) do
    if n[name] > 0 then
      parts[#parts + 1] = icons[name] .. n[name]
    end
  end
  return table.concat(parts, " ")
end

function M.cond()
  local n = status()
  return n.waiting + n.done + n.working > 0
end

function M.color()
  local n = status()
  local group
  if n.waiting > 0 then
    group = "Function" -- orange, matches waybar's attention state
  elseif n.done > 0 then
    group = "DiagnosticOk" -- olive
  else
    group = "Special" -- muted: agents are busy, nothing to do
  end
  local fg = hl(group)
  return fg and { fg = fg } or {}
end

--- Watch the store so a store change repaints the statusline immediately.
function M.setup()
  local dir = state_dir()
  vim.fn.mkdir(dir, "p")

  if not watcher then
    local handle = vim.uv.new_fs_event()
    local started = handle
      and pcall(
        handle.start,
        handle,
        dir,
        {},
        vim.schedule_wrap(function()
          refresh()
        end)
      )
    if started then
      watcher = handle
    elseif handle then
      handle:close()
    end
  end

  -- The legacy counter lives outside the store, so it needs a poll; the same
  -- timer covers a machine where inotify is unavailable. Refresh only when the
  -- counts actually change, not on every tick.
  if not timer then
    last_sig = signature(status())
    timer = vim.uv.new_timer()
    timer:start(
      5000,
      5000,
      vim.schedule_wrap(function()
        local sig = signature(counts())
        if sig ~= last_sig then
          last_sig = sig
          refresh()
        end
      end)
    )
    timer:unref()
  end
end

return M
