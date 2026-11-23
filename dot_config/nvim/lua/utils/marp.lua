-- In-editor Marp slide preview.
--
-- `marp --watch --images png` re-exports every slide of the deck to
-- <cache>/marp/<hash>/slide.NNN.png on each save. A side split shows the PNG
-- of the slide under the cursor through image.nvim (same rendering path as
-- plugins/diagram.lua). The split follows the cursor, and a fs watcher on the
-- output dir re-renders once marp has rewritten the images.
--
-- marp reads the file from disk, so edits show up on :w, not per keystroke.
local M = {}

---@class MarpSession
---@field src integer source buffer
---@field win integer preview window
---@field buf integer preview buffer
---@field outdir string
---@field job integer
---@field watcher uv.uv_fs_event_t?
---@field timer uv.uv_timer_t?
---@field image any
---@field tmp string?
---@field slide integer?
---@field augroup integer

---@type table<integer, MarpSession>
local sessions = {}

-- Themes from dot_config/marp/themes; default_theme applies when the deck
-- has no `theme:` directive of its own.
M.theme_dir = vim.fn.expand("~/.config/marp/themes")
M.default_theme = "flexoki"

-- `theme:` as a global directive, in the front-matter or an HTML comment.
local deck_sets_theme

-- Custom themes (flexoki, generated from the chezmoi palette). `--theme`
-- overrides the deck's own `theme:` directive, so only default to flexoki
-- when the deck doesn't pick a theme itself. `--theme-set` is variadic: keep
-- these args after any positional path.
local function theme_args(src)
  local args = {}
  if vim.fn.isdirectory(M.theme_dir) == 1 then
    vim.list_extend(args, { "--theme-set", M.theme_dir })
    if M.default_theme and not deck_sets_theme(src) then
      vim.list_extend(args, { "--theme", M.default_theme })
    end
  end
  return args
end

function deck_sets_theme(src)
  local lines = vim.api.nvim_buf_get_lines(src, 0, -1, false)
  if lines[1] and lines[1]:match("^%-%-%-%s*$") then
    for i = 2, #lines do
      if lines[i]:match("^%-%-%-%s*$") then
        break
      end
      if lines[i]:match("^theme:") then
        return true
      end
    end
  end
  for _, l in ipairs(lines) do
    if l:match("<!%-%-%s*theme:") then
      return true
    end
  end
  return false
end

-- Marpit splits pages on horizontal rules. A `---` right under a text line is
-- a setext heading, not a rule, so dashes only count after a blank line.
local function is_hr(line)
  local c = line:match("^ ? ? ?([-*_])")
  if not c then
    return false
  end
  local s = line:gsub("%s", "")
  return #s >= 3 and s == c:rep(#s)
end

--- First line (1-based) of every slide. The front-matter belongs to slide 1;
--- a separator line belongs to the slide before it.
local function slide_starts(lines)
  local i = 1
  if lines[1] and lines[1]:match("^%-%-%-%s*$") then
    for j = 2, #lines do
      if lines[j]:match("^%-%-%-%s*$") then
        i = j + 1
        break
      end
    end
  end

  local starts, fence = { 1 }, nil
  for n = i, #lines do
    local l = lines[n]
    local f = l:match("^%s*(```+)") or l:match("^%s*(~~~+)")
    if fence then
      if f and f:sub(1, 1) == fence:sub(1, 1) and #f >= #fence and l:match("^%s*[`~]+%s*$") then
        fence = nil
      end
    elseif f then
      fence = f
    elseif is_hr(l) and (l:match("^%s*[*_]") or n == 1 or lines[n - 1]:match("^%s*$")) then
      table.insert(starts, n + 1)
    end
  end
  return starts
end

--- 1-based slide index containing `row`, and total slide count.
local function slide_at(lines, row)
  local starts = slide_starts(lines)
  local current = 1
  for k, start in ipairs(starts) do
    if start <= row then
      current = k
    end
  end
  return current, #starts
end

--- Title of the slide spanning lines [from, to]: first heading, else first
--- text line that isn't a comment/directive.
local function slide_title(lines, from, to)
  local fallback
  for n = from, math.min(to, #lines) do
    local l = lines[n]
    local h = l:match("^%s*#+%s+(.-)%s*$")
    if h and h ~= "" then
      return h
    end
    if not fallback and l:match("%S") and not l:match("^%s*<!%-%-") and not is_hr(l) then
      fallback = vim.trim(l)
    end
  end
  return fallback or "(empty)"
end

-- Move the cursor to slide `n` (clamped), on its first non-blank line.
local function goto_slide(lines, starts, n)
  n = math.max(1, math.min(n, #starts))
  local row = math.min(starts[n], #lines)
  local last = (starts[n + 1] or #lines + 1) - 1
  for r = row, math.min(last, #lines) do
    if lines[r]:match("%S") and not is_hr(lines[r]) then
      row = r
      break
    end
  end
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  vim.cmd("normal! zv")
end

--- Jump `delta` slides from the one under the cursor (v:count multiplies).
function M.jump(delta)
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local starts = slide_starts(lines)
  local current = slide_at(lines, vim.api.nvim_win_get_cursor(0)[1])
  goto_slide(lines, starts, current + delta * vim.v.count1)
end

--- Pick a slide from a list of titles and jump to it.
function M.pick()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local starts = slide_starts(lines)
  local current = slide_at(lines, vim.api.nvim_win_get_cursor(0)[1])

  local items = {}
  for k, start in ipairs(starts) do
    local title = slide_title(lines, start, (starts[k + 1] or #lines + 1) - 1)
    table.insert(items, {
      idx = k,
      text = k .. " " .. title,
      title = title,
      file = file,
      buf = buf,
      pos = { math.min(start, math.max(#lines, 1)), 0 },
    })
  end

  Snacks.picker.pick({
    title = "Slides",
    items = items,
    layout = { preset = "default" },
    on_show = function(picker)
      picker.list:view(current)
    end,
    format = function(item)
      return {
        { string.format("%3d ", item.idx), item.idx == current and "SnacksPickerMatch" or "SnacksPickerIdx" },
        { item.title },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        -- after close() has handed focus back to the deck window
        vim.schedule(function()
          if vim.api.nvim_get_current_buf() == buf then
            goto_slide(lines, starts, item.idx)
          end
        end)
      end
    end,
  })
end

--- A markdown buffer is a Marp deck when its front-matter says `marp: true`.
function M.is_deck(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 50, false)
  if not (lines[1] and lines[1]:match("^%-%-%-%s*$")) then
    return false
  end
  for i = 2, #lines do
    if lines[i]:match("^%-%-%-%s*$") then
      return false
    end
    if lines[i]:match("^marp:%s*true") then
      return true
    end
  end
  return false
end

--- Slide navigation keys for a deck buffer.
local function set_keys(buf)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
  end
  map("]]", function()
    M.jump(1)
  end, "Marp: next slide")
  map("[[", function()
    M.jump(-1)
  end, "Marp: previous slide")
  map("<leader>ms", M.pick, "Marp: list slides")
end

function M.attach(buf)
  if vim.b[buf].marp_attached then
    return
  end
  vim.b[buf].marp_attached = true
  set_keys(buf)
  -- LazyVim maps ]] / [[ (LSP reference jumps) buffer-locally on LspAttach,
  -- which fires after FileType; take them back once it has run.
  vim.api.nvim_create_autocmd("LspAttach", {
    buffer = buf,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          set_keys(buf)
        end
      end)
    end,
  })
end

local function slide_path(s, n)
  return string.format("%s/slide.%03d.png", s.outdir, n)
end

local function clear_image(s)
  if s.image then
    pcall(function()
      s.image:clear()
    end)
    s.image = nil
  end
  if s.tmp then
    vim.uv.fs_unlink(s.tmp)
    s.tmp = nil
  end
end

---@param s MarpSession
---@param force boolean? re-render even if the slide index didn't change
local function render(s, force)
  if not vim.api.nvim_win_is_valid(s.win) or not vim.api.nvim_buf_is_valid(s.src) then
    M.stop(s.src)
    return
  end

  -- Follow the cursor of whichever window shows the source buffer; fall back
  -- to the last known slide when the source isn't visible.
  local row
  if vim.api.nvim_get_current_buf() == s.src then
    row = vim.api.nvim_win_get_cursor(0)[1]
  else
    local wins = vim.fn.win_findbuf(s.src)
    row = wins[1] and vim.api.nvim_win_get_cursor(wins[1])[1]
  end
  local lines = vim.api.nvim_buf_get_lines(s.src, 0, -1, false)
  local slide, total = slide_at(lines, row or 1)
  if not row and s.slide then
    slide = s.slide
  end
  if slide == s.slide and not force then
    return
  end

  local path = slide_path(s, slide)
  if vim.fn.filereadable(path) == 0 then
    return -- not exported yet (first run, or slide added but not saved)
  end
  s.slide = slide
  vim.wo[s.win].winbar = string.format(" Marp  %d/%d", slide, total)

  -- image.nvim caches by path; a fresh copy forces it to pick up new content.
  local tmp = vim.fn.tempname() .. ".png"
  if not vim.uv.fs_copyfile(path, tmp) then
    return
  end
  clear_image(s)
  s.tmp = tmp
  vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, {})

  s.image = require("image").from_file(tmp, {
    buffer = s.buf,
    window = s.win,
    inline = true,
    x = 0,
    y = 0,
    width = 9999,
    max_height_window_percentage = 100,
  })
  if s.image then
    s.image:render()
  end
end

local function open_window()
  local src_win = vim.api.nvim_get_current_win()
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "marp-preview"
  for opt, val in pairs({
    number = false,
    relativenumber = false,
    signcolumn = "no",
    statuscolumn = "",
    foldcolumn = "0",
    cursorline = false,
    list = false,
  }) do
    vim.wo[win][opt] = val
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", "  Rendering slides…" })
  vim.api.nvim_set_current_win(src_win)
  return win, buf
end

function M.start(src)
  src = src or vim.api.nvim_get_current_buf()
  if sessions[src] then
    return
  end
  local file = vim.api.nvim_buf_get_name(src)
  if file == "" then
    vim.notify("Marp: save the buffer to a file first", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("marp") == 0 then
    vim.notify("Marp: `marp` not found (npm i -g @marp-team/marp-cli)", vim.log.levels.ERROR)
    return
  end

  local outdir = vim.fn.stdpath("cache") .. "/marp/" .. vim.fn.sha256(file):sub(1, 16)
  vim.fn.delete(outdir, "rf")
  vim.fn.mkdir(outdir, "p")

  M.attach(src) -- previewing implies it's a deck, even without `marp: true`
  local win, buf = open_window()
  local s = { src = src, win = win, buf = buf, outdir = outdir } --[[@as MarpSession]]
  sessions[src] = s

  -- The deck goes first: `--theme-set` is variadic and would swallow a
  -- trailing file path as another theme, leaving marp with no input.
  local cmd = {
    "marp",
    file,
    "--watch",
    "--no-stdin",
    "--images",
    "png",
    "--allow-local-files",
    "--output",
    outdir .. "/slide.png",
  }
  vim.list_extend(cmd, theme_args(src))

  s.job = vim.fn.jobstart(cmd, {
    cwd = vim.fn.fnamemodify(file, ":h"),
    stdin = "null", -- marp otherwise waits for markdown on a piped stdin
    stderr_buffered = false,
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if line:find("ERROR", 1, true) then
          vim.notify("Marp: " .. line:gsub("\27%[[%d;]*m", ""), vim.log.levels.ERROR)
        end
      end
    end,
    on_exit = function(_, code)
      -- M.stop() clears the session before killing the job, so any exit
      -- while the session is still live is unexpected (even code 0: e.g.
      -- marp printing its usage and quitting on bad arguments).
      if sessions[src] == s then
        vim.notify("Marp: marp exited unexpectedly (code " .. code .. ")", vim.log.levels.ERROR)
        if vim.api.nvim_buf_is_valid(s.buf) and not s.slide then
          vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, { "", "  marp exited (code " .. code .. ")" })
        end
      end
    end,
  })
  if s.job <= 0 then
    vim.notify("Marp: failed to start marp", vim.log.levels.ERROR)
    M.stop(src)
    return
  end

  -- marp writes all slides in a burst; debounce so we render once at the end.
  s.timer = vim.uv.new_timer()
  s.watcher = vim.uv.new_fs_event()
  s.watcher:start(outdir, {}, function()
    s.timer:stop()
    s.timer:start(
      200,
      0,
      vim.schedule_wrap(function()
        if sessions[src] == s then
          render(s, true)
        end
      end)
    )
  end)

  s.augroup = vim.api.nvim_create_augroup("MarpPreview" .. src, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = s.augroup,
    buffer = src,
    callback = function()
      render(s)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = s.augroup,
    buffer = src,
    callback = function()
      M.stop(src)
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = s.augroup,
    pattern = tostring(win),
    callback = function()
      vim.schedule(function()
        M.stop(src)
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = s.augroup,
    callback = function()
      render(s, true)
    end,
  })

  vim.keymap.set("n", "q", function()
    M.stop(src)
  end, { buffer = buf, desc = "Close Marp preview" })
end

function M.stop(src)
  src = src or vim.api.nvim_get_current_buf()
  local s = sessions[src]
  if not s then
    return
  end
  sessions[src] = nil
  pcall(vim.fn.jobstop, s.job)
  if s.watcher then
    s.watcher:stop()
    s.watcher:close()
  end
  if s.timer then
    s.timer:stop()
    s.timer:close()
  end
  clear_image(s)
  pcall(vim.api.nvim_del_augroup_by_id, s.augroup)
  if vim.api.nvim_win_is_valid(s.win) and #vim.api.nvim_list_wins() > 1 then
    pcall(vim.api.nvim_win_close, s.win, true)
  end
  vim.fn.delete(s.outdir, "rf")
end

function M.toggle(src)
  src = src or vim.api.nvim_get_current_buf()
  if sessions[src] then
    M.stop(src)
  else
    M.start(src)
  end
end

-- Browser preview: `marp --server` on the deck's directory (so relative
-- image paths resolve), opened in the default browser. marp's server
-- reloads the page whenever a file in the directory is saved.

---@type table<integer, { job: integer, url: string? }>
local servers = {}

local function free_port()
  local tcp = vim.uv.new_tcp()
  tcp:bind("127.0.0.1", 0)
  local port = tcp:getsockname().port
  tcp:close()
  return port
end

function M.browser_stop(src)
  src = src or vim.api.nvim_get_current_buf()
  local srv = servers[src]
  if srv then
    servers[src] = nil
    pcall(vim.fn.jobstop, srv.job)
  end
end

--- Open the deck in the browser; a second call stops the server.
function M.browser(src)
  src = src or vim.api.nvim_get_current_buf()
  if servers[src] then
    M.browser_stop(src)
    vim.notify("Marp: browser preview stopped", vim.log.levels.INFO)
    return
  end
  local file = vim.api.nvim_buf_get_name(src)
  if file == "" then
    vim.notify("Marp: save the buffer to a file first", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("marp") == 0 then
    vim.notify("Marp: `marp` not found (npm i -g @marp-team/marp-cli)", vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.fnamemodify(file, ":h")
  local port = free_port()
  local url = string.format("http://localhost:%d/%s", port, vim.uri_encode(vim.fn.fnamemodify(file, ":t")))
  local srv = { url = url }
  servers[src] = srv

  local cmd = { "marp", "--no-stdin", "--server", "--input-dir", dir }
  vim.list_extend(cmd, theme_args(src))
  local opened = false
  srv.job = vim.fn.jobstart(cmd, {
    cwd = dir,
    env = { PORT = tostring(port) },
    stdin = "null",
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if not opened and line:find("Start server listened", 1, true) then
          opened = true
          vim.schedule(function()
            vim.ui.open(url)
          end)
        elseif line:find("ERROR", 1, true) then
          vim.notify("Marp: " .. line:gsub("\27%[[%d;]*m", ""), vim.log.levels.ERROR)
        end
      end
    end,
    on_exit = function(_, code)
      if servers[src] == srv then
        servers[src] = nil
        vim.notify("Marp: server exited unexpectedly (code " .. code .. ")", vim.log.levels.ERROR)
      end
    end,
  })
  if srv.job <= 0 then
    servers[src] = nil
    vim.notify("Marp: failed to start marp server", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    buffer = src,
    once = true,
    callback = function()
      M.browser_stop(src)
    end,
  })
end

M._slide_at = slide_at -- exposed for testing

return M
