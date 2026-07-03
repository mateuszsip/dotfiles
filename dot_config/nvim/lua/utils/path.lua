local M = {}

--- Git toplevel for `path` (walks upward looking for `.git`), or nil.
--- @param path string absolute path
--- @return string|nil
function M.git_toplevel(path)
  local found = vim.fs.find({ ".git" }, { upward = true, path = path, type = "directory" })
  return found[1] and vim.fs.dirname(found[1]) or nil
end

--- Copy the relative path of `path` to the system clipboard (+) and yank register (").
--- @param path string absolute path
--- @param base string|nil base dir to relativize against (defaults to cwd)
--- @param opts table|nil { dir = boolean }
function M.copy_relative(path, base, opts)
  opts = opts or {}
  base = base or vim.uv.cwd()
  local rel = vim.fs.relpath(base, path)
  if rel == nil then
    rel = path
  end
  if opts.dir and not rel:match("/$") then
    rel = rel .. "/"
  end
  vim.fn.setreg("+", rel)
  vim.fn.setreg('"', rel)
  Snacks.notify("Copied: " .. rel)
end

return M