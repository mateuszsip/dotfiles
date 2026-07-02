local M = {}

local history = {} ---@type string[]
local max = 50
local file = vim.fn.stdpath("data") .. "/cwd_history.json"

--- current global cwd (normalized)
local function cwd()
  return vim.uv.cwd() or vim.fn.getcwd()
end

local function load()
  local f = io.open(file, "r")
  if not f then
    return
  end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then
    return
  end
  local ok, data = pcall(vim.json.decode, content)
  if ok and type(data) == "table" then
    for _, dir in ipairs(data) do
      if type(dir) == "string" and dir ~= "" then
        history[#history + 1] = dir
      end
    end
  end
end

local function save()
  local ok, json = pcall(vim.json.encode, history)
  if not ok then
    return
  end
  local f = io.open(file, "w")
  if not f then
    return
  end
  f:write(json)
  f:close()
end

-- move `dir` to the front of history (dedupe + cap)
local function push(dir)
  if not dir or dir == "" then
    return
  end
  for i = #history, 1, -1 do
    if history[i] == dir then
      table.remove(history, i)
    end
  end
  table.insert(history, 1, dir)
  while #history > max do
    table.remove(history, #history)
  end
  save()
end

load()
-- seed with the cwd at first load (also creates the file if missing)
push(cwd())

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("cwd_history", { clear = true }),
  callback = function(ev)
    push(ev.file)
  end,
})
-- belt and suspenders: persist on exit too
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("cwd_history_save", { clear = true }),
  callback = save,
})

function M.history()
  return history
end

function M.pick()
  if #history == 0 then
    return Snacks.notify.warn("No cwd history yet")
  end
  local items = {} ---@type snacks.picker.finder.Item[]
  local seen = {}
  for _, dir in ipairs(history) do
    if not seen[dir] then
      seen[dir] = true
      items[#items + 1] = { text = vim.fn.fnamemodify(dir, ":~"), file = dir }
    end
  end
  local cur = cwd()
  Snacks.picker({
    title = "CWD History",
    items = items,
    format = function(item)
      local marker = (item.file == cur) and "• " or "  "
      return { { marker .. item.text, hl = "Directory" } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          vim.fn.chdir(item.file)
          vim.notify("cd " .. vim.fn.fnamemodify(item.file, ":~"))
        end)
      end
    end,
  })
end

return M
