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

--- 1-based slide index containing `row`, and total slide count.
local function slide_at(lines, row)
  local i = 1
  if lines[1] and lines[1]:match("^%-%-%-%s*$") then
    for j = 2, #lines do
      if lines[j]:match("^%-%-%-%s*$") then
        i = j + 1
        break
      end
    end
  end

  local idx, current, fence = 1, 1, nil
  for n = i, #lines do
    if n == row then
      current = idx
    end
    local l = lines[n]
    local f = l:match("^%s*(```+)") or l:match("^%s*(~~~+)")
    if fence then
      if f and f:sub(1, 1) == fence:sub(1, 1) and #f >= #fence and l:match("^%s*[`~]+%s*$") then
        fence = nil
      end
    elseif f then
      fence = f
    elseif is_hr(l) and (l:match("^%s*[*_]") or n == 1 or lines[n - 1]:match("^%s*$")) then
      idx = idx + 1
    end
  end
  if row > #lines then
    current = idx
  end
  return current, idx
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

  local win, buf = open_window()
  local s = { src = src, win = win, buf = buf, outdir = outdir } --[[@as MarpSession]]
  sessions[src] = s

  s.job = vim.fn.jobstart({
    "marp",
    "--watch",
    "--no-stdin",
    "--images",
    "png",
    "--allow-local-files",
    "--output",
    outdir .. "/slide.png",
    file,
  }, {
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
      if sessions[src] == s and code ~= 0 and code ~= 143 then
        vim.notify("Marp: marp exited with code " .. code, vim.log.levels.ERROR)
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

M._slide_at = slide_at -- exposed for testing

return M
